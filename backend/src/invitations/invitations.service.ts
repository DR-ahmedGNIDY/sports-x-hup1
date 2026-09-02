import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ClubManagedPlayer } from '../club-players/schemas/club-managed-player.schema';
import { ClubsService } from '../clubs/clubs.service';
import { ClubProfileDocument } from '../clubs/schemas/club-profile.schema';
import { NotificationsService } from '../notifications/notifications.service';
import {
  NotificationActorRole,
  NotificationEntityType,
  NotificationParams,
  NotificationType,
} from '../notifications/schemas/notification.schema';
import { PlayersService } from '../players/players.service';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';

import {
  CreateClubToPlayerInvitationDto,
  CreatePlayerToClubInvitationDto,
} from './dto/create-invitation.dto';
import { ListInvitationsDto } from './dto/list-invitations.dto';
import {
  DUPLICATE_KEY_ERROR_CODE,
  MembershipConflictError,
  MembershipsService,
} from './memberships.service';
import {
  ClubPlayerInvitation,
  ClubPlayerInvitationDocument,
  defaultExpiresAt,
  InvitationStatus,
  InvitationType,
} from './schemas/club-player-invitation.schema';

const INVITATIONS_PAGE_SIZE = 20;

// An invitation plus the two profiles it names, resolved in bulk for a whole
// page rather than per row — the mapper needs a name, a photo and a code for
// both sides, and neither profile is guaranteed to still exist.
export interface HydratedInvitation {
  invitation: ClubPlayerInvitationDocument;
  clubProfile: ClubProfileDocument | null;
  playerProfile: PlayerProfileDocument | null;
}

export interface HydratedInvitationPage {
  items: HydratedInvitation[];
  page: number;
  pageSize: number;
  total: number;
}

export interface InvitationsSummary {
  pendingReceived: number;
  pendingSent: number;
}

@Injectable()
export class InvitationsService {
  private readonly logger = new Logger(InvitationsService.name);

  constructor(
    @InjectModel(ClubPlayerInvitation.name)
    private readonly invitationModel: Model<ClubPlayerInvitation>,
    // Registered directly by InvitationsModule rather than by importing
    // ClubPlayersModule — this only ever *reads* the ownership row as a
    // business-rule guard (a club-created account already belongs to a club),
    // and importing the module for one read would couple the two features.
    @InjectModel(ClubManagedPlayer.name)
    private readonly clubManagedPlayerModel: Model<ClubManagedPlayer>,
    private readonly memberships: MembershipsService,
    private readonly playersService: PlayersService,
    private readonly clubsService: ClubsService,
    private readonly notifications: NotificationsService,
  ) {}

  // ---------------------------------------------------------- notifying
  //
  // Every call below happens *after* the transition it announces has already
  // committed. A notification that failed to record must not turn a
  // successful accept into an error: the membership is the fact, this is
  // only the announcement of it.
  //
  // `NotificationsService.emit` already swallows its own failures, and this
  // catches too. That is deliberate rather than redundant: without it, this
  // service's correctness would depend on a promise made in another class's
  // doc comment, and the day someone makes emit() throw, invitations break
  // instead of notifications. A test pins the behaviour from this side.
  //
  // Deliberately not an event bus. This codebase has none, and adding one
  // for a single producer and a single consumer buys indirection rather than
  // decoupling — a direct call is honest about what actually happens.

  private async safely(announce: () => Promise<unknown>): Promise<void> {
    try {
      await announce();
    } catch {
      this.logger.error('Failed to announce an invitation event.');
    }
  }

  private async notifyRecipientOfNewInvitation(
    row: HydratedInvitation,
  ): Promise<void> {
    const { invitation } = row;
    // The recipient is told who wrote to them, which is the *other* side:
    // a club-to-player invitation names the club, and vice versa.
    const fromClub = invitation.type === InvitationType.CLUB_TO_PLAYER;
    await this.safely(() =>
      this.notifications.emit({
        userId: invitation.recipientUserId,
        type: NotificationType.INVITATION_RECEIVED,
        entityType: NotificationEntityType.INVITATION,
        entityId: invitation._id,
        params: fromClub ? this.clubActor(row) : this.playerActor(row),
      }),
    );
  }

  private async notifySenderOfResponse(
    row: HydratedInvitation,
    type: NotificationType,
  ): Promise<void> {
    const { invitation } = row;
    // The responder is the recipient of the original invitation, so the
    // actor here is the opposite side from the one above.
    const respondedByPlayer =
      invitation.type === InvitationType.CLUB_TO_PLAYER;
    await this.safely(() =>
      this.notifications.emit({
        userId: invitation.senderUserId,
        type,
        entityType: NotificationEntityType.INVITATION,
        entityId: invitation._id,
        params: respondedByPlayer ? this.playerActor(row) : this.clubActor(row),
      }),
    );
  }

  private clubActor(row: HydratedInvitation): NotificationParams {
    return {
      actorRole: NotificationActorRole.CLUB,
      actorName: row.clubProfile?.name,
      actorProfileId: row.clubProfile?._id.toString(),
      actorPublicCode: row.clubProfile?.publicCode,
    };
  }

  private playerActor(row: HydratedInvitation): NotificationParams {
    const profile = row.playerProfile;
    const name = [profile?.firstName, profile?.lastName]
      .filter((part) => part && part.length > 0)
      .join(' ');
    return {
      actorRole: NotificationActorRole.PLAYER,
      actorName: name.length > 0 ? name : undefined,
      actorProfileId: profile?._id.toString(),
      actorPublicCode: profile?.publicCode,
    };
  }

  // ---------------------------------------------------------------- sending

  async sendClubToPlayer(
    clubUserId: string,
    dto: CreateClubToPlayerInvitationDto,
  ): Promise<HydratedInvitation> {
    const clubProfile = await this.requireOwnClubProfile(clubUserId);
    const playerProfile = await this.resolvePlayer(dto);

    return this.createInvitation({
      type: InvitationType.CLUB_TO_PLAYER,
      clubProfile,
      playerProfile,
      message: dto.message,
    });
  }

  async sendPlayerToClub(
    playerUserId: string,
    dto: CreatePlayerToClubInvitationDto,
  ): Promise<HydratedInvitation> {
    const playerProfile =
      await this.playersService.getOrCreateForUser(playerUserId);
    const clubProfile = await this.resolveClub(dto);

    return this.createInvitation({
      type: InvitationType.PLAYER_TO_CLUB,
      clubProfile,
      playerProfile,
      message: dto.message,
    });
  }

  private async requireOwnClubProfile(
    clubUserId: string,
  ): Promise<ClubProfileDocument> {
    // getOrCreate (not findByUserId): a club that has never opened its
    // profile editor still has a valid account and must be able to recruit.
    // This is also where its public code gets allocated if it had none.
    return this.clubsService.getOrCreateForUser(clubUserId);
  }

  private async resolvePlayer(
    dto: CreateClubToPlayerInvitationDto,
  ): Promise<PlayerProfileDocument> {
    if (dto.playerCode) {
      return this.playersService.findPublicByCodeOrThrow(dto.playerCode);
    }
    if (dto.playerId) {
      return this.playersService.findPublicByIdOrThrow(dto.playerId);
    }
    throw new BadRequestException(
      'Provide either a player code or a player id.',
    );
  }

  private async resolveClub(
    dto: CreatePlayerToClubInvitationDto,
  ): Promise<ClubProfileDocument> {
    if (dto.clubCode) {
      return this.clubsService.findByPublicCodeOrThrow(dto.clubCode);
    }
    if (dto.clubId) {
      return this.clubsService.findByIdOrThrow(dto.clubId);
    }
    throw new BadRequestException('Provide either a club code or a club id.');
  }

  // Every send funnels through here, so the business rules hold identically
  // in both directions and there is one place to audit them.
  private async createInvitation(input: {
    type: InvitationType;
    clubProfile: ClubProfileDocument;
    playerProfile: PlayerProfileDocument;
    message?: string;
  }): Promise<HydratedInvitation> {
    const { type, clubProfile, playerProfile, message } = input;
    const clubUserId = clubProfile.userId;
    const playerUserId = playerProfile.userId;

    // Rule 2 — nobody invites themselves. Unreachable through the current
    // role guards (one account is either a club or a player, never both),
    // which is exactly why it's cheap to assert rather than assume.
    if (clubUserId.toString() === playerUserId.toString()) {
      throw new BadRequestException('You cannot invite yourself.');
    }

    // Rule 5 — one club at a time. Checked here for a clear error message;
    // the unique index on the membership is what actually guarantees it.
    const activeMembership = await this.memberships.findActiveForPlayer(
      playerUserId.toString(),
    );
    if (activeMembership) {
      throw new ConflictException(
        activeMembership.clubUserId.toString() === clubUserId.toString()
          ? 'This player is already a member of your club.'
          : 'This player already belongs to a club.',
      );
    }

    // Rule 6 — a club-created account already belongs to the club that
    // created it. ClubManagedPlayer is never written here, only read.
    const managed = await this.clubManagedPlayerModel.findOne({
      userId: playerUserId,
    });
    if (managed) {
      throw new ConflictException(
        managed.clubId.toString() === clubUserId.toString()
          ? 'This player is already managed by your club.'
          : 'This player is already managed by another club.',
      );
    }

    const [senderUserId, recipientUserId] =
      type === InvitationType.CLUB_TO_PLAYER
        ? [clubUserId, playerUserId]
        : [playerUserId, clubUserId];

    // The duplicate-pending index doesn't know about expiry, so a lapsed
    // invitation still occupies this pair's one PENDING slot until its stored
    // status catches up. Without this, an invitation nobody ever answered
    // would silently bar the pair from ever trying again. Scoped to this one
    // pair (indexed), so it costs one small update, not a sweep.
    await this.expireLapsedForPair(clubUserId, playerUserId);

    try {
      const invitation = await this.invitationModel.create({
        type,
        status: InvitationStatus.PENDING,
        clubUserId,
        playerUserId,
        senderUserId,
        recipientUserId,
        message,
        expiresAt: defaultExpiresAt(),
      });
      const row = { invitation, clubProfile, playerProfile };
      await this.notifyRecipientOfNewInvitation(row);
      return row;
    } catch (error) {
      // Rule 4 — the partial unique index on the pending pair fired. Two
      // simultaneous sends (or a send racing the other side's request) land
      // here rather than creating a second live invitation.
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new ConflictException(
          'There is already a pending invitation between this club and this player.',
        );
      }
      throw error;
    }
  }

  private async expireLapsedForPair(
    clubUserId: Types.ObjectId | string,
    playerUserId: Types.ObjectId | string,
  ): Promise<void> {
    await this.invitationModel.updateMany(
      {
        clubUserId,
        playerUserId,
        status: InvitationStatus.PENDING,
        expiresAt: { $lte: new Date() },
      },
      { $set: { status: InvitationStatus.EXPIRED } },
    );
  }

  // --------------------------------------------------------------- reading

  async listReceived(
    userId: string,
    dto: ListInvitationsDto,
  ): Promise<HydratedInvitationPage> {
    return this.listBy({ recipientUserId: userId }, dto);
  }

  async listSent(
    userId: string,
    dto: ListInvitationsDto,
  ): Promise<HydratedInvitationPage> {
    return this.listBy({ senderUserId: userId }, dto);
  }

  private async listBy(
    scope: Record<string, unknown>,
    dto: ListInvitationsDto,
  ): Promise<HydratedInvitationPage> {
    // `scope` always pins one side to the caller, so no query in this file
    // can return an invitation the caller is not party to.
    const filter: Record<string, unknown> = { ...scope };
    if (dto.status) filter.status = dto.status;
    const page = dto.page ?? 1;

    const [items, total] = await Promise.all([
      this.invitationModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * INVITATIONS_PAGE_SIZE)
        .limit(INVITATIONS_PAGE_SIZE),
      this.invitationModel.countDocuments(filter),
    ]);

    return {
      items: await this.hydrate(items),
      page,
      pageSize: INVITATIONS_PAGE_SIZE,
      total,
    };
  }

  async summary(userId: string): Promise<InvitationsSummary> {
    const [pendingReceived, pendingSent] = await Promise.all([
      this.invitationModel.countDocuments({
        recipientUserId: userId,
        status: InvitationStatus.PENDING,
        expiresAt: { $gt: new Date() },
      }),
      this.invitationModel.countDocuments({
        senderUserId: userId,
        status: InvitationStatus.PENDING,
        expiresAt: { $gt: new Date() },
      }),
    ]);
    return { pendingReceived, pendingSent };
  }

  // The scope is part of the query, not a check performed afterwards: a
  // caller who is neither party matches nothing and gets the same 404 as a
  // caller who invented the id. Nothing distinguishes "not yours" from
  // "doesn't exist" (IDOR + enumeration).
  async findByIdForParty(
    userId: string,
    id: string,
  ): Promise<HydratedInvitation> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Invitation not found.');
    }
    const invitation = await this.invitationModel.findOne({
      _id: id,
      $or: [{ senderUserId: userId }, { recipientUserId: userId }],
    });
    if (!invitation) {
      throw new NotFoundException('Invitation not found.');
    }
    const [hydrated] = await this.hydrate([invitation]);
    return hydrated;
  }

  // One query per profile collection for the whole page, not per row.
  private async hydrate(
    invitations: ClubPlayerInvitationDocument[],
  ): Promise<HydratedInvitation[]> {
    if (invitations.length === 0) return [];

    const clubUserIds = [
      ...new Set(invitations.map((i) => i.clubUserId.toString())),
    ];
    const playerUserIds = [
      ...new Set(invitations.map((i) => i.playerUserId.toString())),
    ];
    const [clubProfiles, playerProfiles] = await Promise.all([
      this.clubsService.findManyByUserIds(clubUserIds),
      this.playersService.findManyByUserIds(playerUserIds),
    ]);
    const clubByUserId = new Map(
      clubProfiles.map((p) => [p.userId.toString(), p]),
    );
    const playerByUserId = new Map(
      playerProfiles.map((p) => [p.userId.toString(), p]),
    );

    return invitations.map((invitation) => ({
      invitation,
      clubProfile: clubByUserId.get(invitation.clubUserId.toString()) ?? null,
      playerProfile:
        playerByUserId.get(invitation.playerUserId.toString()) ?? null,
    }));
  }

  // ------------------------------------------------------------ responding

  async accept(userId: string, id: string): Promise<HydratedInvitation> {
    // Single atomic claim — recipient, PENDING and not-expired are all part
    // of the filter, so a double-accept, an accept by the sender, and an
    // accept of a lapsed invitation all match nothing on the second/wrong
    // attempt. No read-then-write window exists.
    const invitation = await this.transition(
      userId,
      id,
      'recipientUserId',
      InvitationStatus.ACCEPTED,
    );

    try {
      await this.memberships.create({
        clubUserId: invitation.clubUserId,
        playerUserId: invitation.playerUserId,
        invitationId: invitation._id,
      });
    } catch (error) {
      if (error instanceof MembershipConflictError) {
        // Another club's invitation won the race between the claim above and
        // this insert. Put the invitation back so it is not silently burnt —
        // guarded on the status we ourselves just wrote, so this can never
        // resurrect an invitation somebody else has since resolved.
        await this.invitationModel.updateOne(
          { _id: invitation._id, status: InvitationStatus.ACCEPTED },
          {
            $set: { status: InvitationStatus.PENDING },
            $unset: { respondedAt: 1 },
          },
        );
        throw new ConflictException(error.message);
      }
      throw error;
    }

    // The player now has a club, so every other live invitation naming them
    // has become unacceptable (the membership index would reject it). Close
    // them explicitly rather than leaving the player with buttons that can
    // only fail.
    await this.invitationModel.updateMany(
      {
        playerUserId: invitation.playerUserId,
        status: InvitationStatus.PENDING,
        _id: { $ne: invitation._id },
      },
      {
        $set: {
          status: InvitationStatus.CANCELLED,
          respondedAt: new Date(),
        },
      },
    );

    const [hydrated] = await this.hydrate([invitation]);
    await this.notifySenderOfResponse(
      hydrated,
      NotificationType.INVITATION_ACCEPTED,
    );
    return hydrated;
  }

  async reject(userId: string, id: string): Promise<HydratedInvitation> {
    const invitation = await this.transition(
      userId,
      id,
      'recipientUserId',
      InvitationStatus.REJECTED,
    );
    const [hydrated] = await this.hydrate([invitation]);
    await this.notifySenderOfResponse(
      hydrated,
      NotificationType.INVITATION_REJECTED,
    );
    return hydrated;
  }

  // Cancel is the sender's mirror of reject — "I take it back". There is no
  // separate WITHDRAWN state; see the plan's state machine.
  async cancel(userId: string, id: string): Promise<HydratedInvitation> {
    const invitation = await this.transition(
      userId,
      id,
      'senderUserId',
      InvitationStatus.CANCELLED,
    );
    const [hydrated] = await this.hydrate([invitation]);
    return hydrated;
  }

  private async transition(
    userId: string,
    id: string,
    party: 'senderUserId' | 'recipientUserId',
    next: InvitationStatus,
  ): Promise<ClubPlayerInvitationDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Invitation not found.');
    }
    const now = new Date();
    const updated = await this.invitationModel.findOneAndUpdate(
      {
        _id: id,
        [party]: userId,
        status: InvitationStatus.PENDING,
        expiresAt: { $gt: now },
      },
      { $set: { status: next, respondedAt: now } },
      { new: true },
    );
    if (updated) return updated;

    // The claim failed. Work out why — but only from invitations the caller
    // is actually party to, so this diagnosis can't be used to probe for
    // other people's ids.
    return this.explainFailedTransition(userId, id, party);
  }

  private async explainFailedTransition(
    userId: string,
    id: string,
    party: 'senderUserId' | 'recipientUserId',
  ): Promise<never> {
    const visible = await this.invitationModel.findOne({
      _id: id,
      $or: [{ senderUserId: userId }, { recipientUserId: userId }],
    });
    if (!visible) {
      throw new NotFoundException('Invitation not found.');
    }
    if (visible[party].toString() !== userId) {
      // The caller is the *other* party — e.g. the sender trying to accept
      // their own invitation. They may see the invitation, so a 403 tells
      // them something true without revealing anything they can't already
      // read.
      throw new ForbiddenException(
        party === 'recipientUserId'
          ? 'Only the recipient can respond to this invitation.'
          : 'Only the sender can cancel this invitation.',
      );
    }
    if (visible.status !== InvitationStatus.PENDING) {
      throw new ConflictException('This invitation has already been resolved.');
    }
    throw new ConflictException('This invitation has expired.');
  }

  // Maintenance: make stored status match reality for invitations that have
  // lapsed. Nothing depends on this having run — every read computes the
  // effective status and every transition filters on `expiresAt` — it just
  // keeps the collection honest for reporting.
  async markExpired(now: Date = new Date()): Promise<number> {
    const result = await this.invitationModel.updateMany(
      { status: InvitationStatus.PENDING, expiresAt: { $lte: now } },
      { $set: { status: InvitationStatus.EXPIRED } },
    );
    return result.modifiedCount ?? 0;
  }
}
