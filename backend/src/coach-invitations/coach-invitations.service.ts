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
import {
  ClubAccessService,
  CoachMembershipConflictError,
  DUPLICATE_KEY_ERROR_CODE,
} from '../club-access/club-access.service';
import { ClubsService } from '../clubs/clubs.service';
import { ClubProfileDocument } from '../clubs/schemas/club-profile.schema';
import { coachDisplayName } from '../coaches/coaches.mapper';
import { CoachesService } from '../coaches/coaches.service';
import { CoachProfileDocument } from '../coaches/schemas/coach-profile.schema';
import { ListInvitationsDto } from '../invitations/dto/list-invitations.dto';
import { InvitationStatus } from '../invitations/schemas/club-player-invitation.schema';
import { NotificationsService } from '../notifications/notifications.service';
import {
  NotificationActorRole,
  NotificationEntityType,
  NotificationParams,
  NotificationType,
} from '../notifications/schemas/notification.schema';
import {
  CreateClubToCoachInvitationDto,
  CreateCoachToClubInvitationDto,
} from './dto/coach-invitation.dto';
import {
  ClubCoachInvitation,
  ClubCoachInvitationDocument,
  CoachInvitationType,
} from './schemas/club-coach-invitation.schema';
import { defaultExpiresAt } from '../invitations/schemas/club-player-invitation.schema';

const PAGE_SIZE = 20;

export interface HydratedCoachInvitation {
  invitation: ClubCoachInvitationDocument;
  clubProfile: ClubProfileDocument | null;
  coachProfile: CoachProfileDocument | null;
}

export interface HydratedCoachInvitationPage {
  items: HydratedCoachInvitation[];
  page: number;
  pageSize: number;
  total: number;
}

// Mirrors InvitationsService (club↔player) rule for rule, with one
// difference: a coach may be on several clubs' staff, so accepting one club
// does not close a coach's other pending invitations.
@Injectable()
export class CoachInvitationsService {
  private readonly logger = new Logger(CoachInvitationsService.name);

  constructor(
    @InjectModel(ClubCoachInvitation.name)
    private readonly invitationModel: Model<ClubCoachInvitation>,
    private readonly access: ClubAccessService,
    private readonly clubsService: ClubsService,
    private readonly coachesService: CoachesService,
    private readonly notifications: NotificationsService,
  ) {}

  // -------------------------------------------------------------- sending

  async sendClubToCoach(
    clubUserId: string,
    dto: CreateClubToCoachInvitationDto,
  ): Promise<HydratedCoachInvitation> {
    const clubProfile = await this.clubsService.getOrCreateForUser(clubUserId);
    let coachProfile: CoachProfileDocument;
    if (dto.coachCode) {
      coachProfile = await this.coachesService.findPublicByCodeOrThrow(
        dto.coachCode,
      );
    } else if (dto.coachId) {
      coachProfile = await this.coachesService.findPublicByIdOrThrow(
        dto.coachId,
      );
    } else {
      throw new BadRequestException(
        'Provide either a coach code or a coach id.',
      );
    }
    return this.create(
      CoachInvitationType.CLUB_TO_COACH,
      clubProfile,
      coachProfile,
      dto.message,
    );
  }

  async sendCoachToClub(
    coachUserId: string,
    dto: CreateCoachToClubInvitationDto,
  ): Promise<HydratedCoachInvitation> {
    const coachProfile =
      await this.coachesService.getOrCreateForUser(coachUserId);
    let clubProfile: ClubProfileDocument;
    if (dto.clubCode) {
      clubProfile = await this.clubsService.findByPublicCodeOrThrow(
        dto.clubCode,
      );
    } else if (dto.clubId) {
      clubProfile = await this.clubsService.findByIdOrThrow(dto.clubId);
    } else {
      throw new BadRequestException('Provide either a club code or a club id.');
    }
    return this.create(
      CoachInvitationType.COACH_TO_CLUB,
      clubProfile,
      coachProfile,
      dto.message,
    );
  }

  private async create(
    type: CoachInvitationType,
    clubProfile: ClubProfileDocument,
    coachProfile: CoachProfileDocument,
    message?: string,
  ): Promise<HydratedCoachInvitation> {
    const clubUserId = clubProfile.userId;
    const coachUserId = coachProfile.userId;

    if (await this.access.findActive(clubUserId, coachUserId)) {
      throw new ConflictException(
        'This coach is already on this club’s staff.',
      );
    }

    const [senderUserId, recipientUserId] =
      type === CoachInvitationType.CLUB_TO_COACH
        ? [clubUserId, coachUserId]
        : [coachUserId, clubUserId];

    // A lapsed invitation would otherwise hold the pair's one PENDING slot.
    await this.invitationModel.updateMany(
      {
        clubUserId,
        coachUserId,
        status: InvitationStatus.PENDING,
        expiresAt: { $lte: new Date() },
      },
      { $set: { status: InvitationStatus.EXPIRED } },
    );

    try {
      const invitation = await this.invitationModel.create({
        type,
        status: InvitationStatus.PENDING,
        clubUserId,
        coachUserId,
        senderUserId,
        recipientUserId,
        message,
        expiresAt: defaultExpiresAt(),
      });
      const row = { invitation, clubProfile, coachProfile };
      await this.announce(
        row,
        invitation.recipientUserId,
        NotificationType.INVITATION_RECEIVED,
        type === CoachInvitationType.CLUB_TO_COACH ? 'club' : 'coach',
      );
      return row;
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new ConflictException(
          'There is already a pending invitation between this club and this coach.',
        );
      }
      throw error;
    }
  }

  // ------------------------------------------------------------- reading

  listReceived(userId: string, dto: ListInvitationsDto) {
    return this.listBy({ recipientUserId: userId }, dto);
  }

  listSent(userId: string, dto: ListInvitationsDto) {
    return this.listBy({ senderUserId: userId }, dto);
  }

  private async listBy(
    scope: Record<string, unknown>,
    dto: ListInvitationsDto,
  ): Promise<HydratedCoachInvitationPage> {
    const filter: Record<string, unknown> = { ...scope };
    if (dto.status) filter.status = dto.status;
    const page = dto.page ?? 1;
    const [items, total] = await Promise.all([
      this.invitationModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * PAGE_SIZE)
        .limit(PAGE_SIZE),
      this.invitationModel.countDocuments(filter),
    ]);
    return {
      items: await this.hydrate(items),
      page,
      pageSize: PAGE_SIZE,
      total,
    };
  }

  async summary(userId: string) {
    const now = new Date();
    const [pendingReceived, pendingSent] = await Promise.all([
      this.invitationModel.countDocuments({
        recipientUserId: userId,
        status: InvitationStatus.PENDING,
        expiresAt: { $gt: now },
      }),
      this.invitationModel.countDocuments({
        senderUserId: userId,
        status: InvitationStatus.PENDING,
        expiresAt: { $gt: now },
      }),
    ]);
    return { pendingReceived, pendingSent };
  }

  // Party-scoped in the query: "not yours" and "doesn't exist" are the
  // same 404.
  async findByIdForParty(
    userId: string,
    id: string,
  ): Promise<HydratedCoachInvitation> {
    const invitation = Types.ObjectId.isValid(id)
      ? await this.invitationModel.findOne({
          _id: id,
          $or: [{ senderUserId: userId }, { recipientUserId: userId }],
        })
      : null;
    if (!invitation) {
      throw new NotFoundException('Invitation not found.');
    }
    const [row] = await this.hydrate([invitation]);
    return row;
  }

  private async hydrate(
    invitations: ClubCoachInvitationDocument[],
  ): Promise<HydratedCoachInvitation[]> {
    if (invitations.length === 0) return [];
    const [clubs, coaches] = await Promise.all([
      this.clubsService.findManyByUserIds([
        ...new Set(invitations.map((i) => i.clubUserId.toString())),
      ]),
      this.coachesService.findManyByUserIds([
        ...new Set(invitations.map((i) => i.coachUserId.toString())),
      ]),
    ]);
    const clubBy = new Map(clubs.map((c) => [c.userId.toString(), c]));
    const coachBy = new Map(coaches.map((c) => [c.userId.toString(), c]));
    return invitations.map((invitation) => ({
      invitation,
      clubProfile: clubBy.get(invitation.clubUserId.toString()) ?? null,
      coachProfile: coachBy.get(invitation.coachUserId.toString()) ?? null,
    }));
  }

  // ----------------------------------------------------------- responding

  async accept(userId: string, id: string): Promise<HydratedCoachInvitation> {
    const invitation = await this.transition(
      userId,
      id,
      'recipientUserId',
      InvitationStatus.ACCEPTED,
    );
    try {
      await this.access.create({
        clubUserId: invitation.clubUserId,
        coachUserId: invitation.coachUserId,
        invitationId: invitation._id,
      });
    } catch (error) {
      if (error instanceof CoachMembershipConflictError) {
        // Already on staff by some other route — put the invitation back
        // rather than burning it, guarded on the status we just wrote.
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
    const [row] = await this.hydrate([invitation]);
    await this.announceResponse(row, NotificationType.INVITATION_ACCEPTED);
    return row;
  }

  async reject(userId: string, id: string): Promise<HydratedCoachInvitation> {
    const invitation = await this.transition(
      userId,
      id,
      'recipientUserId',
      InvitationStatus.REJECTED,
    );
    const [row] = await this.hydrate([invitation]);
    await this.announceResponse(row, NotificationType.INVITATION_REJECTED);
    return row;
  }

  async cancel(userId: string, id: string): Promise<HydratedCoachInvitation> {
    const invitation = await this.transition(
      userId,
      id,
      'senderUserId',
      InvitationStatus.CANCELLED,
    );
    const [row] = await this.hydrate([invitation]);
    return row;
  }

  // One atomic claim: party, PENDING and not-expired are all in the filter.
  private async transition(
    userId: string,
    id: string,
    party: 'senderUserId' | 'recipientUserId',
    next: InvitationStatus,
  ): Promise<ClubCoachInvitationDocument> {
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

    const visible = await this.invitationModel.findOne({
      _id: id,
      $or: [{ senderUserId: userId }, { recipientUserId: userId }],
    });
    if (!visible) {
      throw new NotFoundException('Invitation not found.');
    }
    if (visible[party].toString() !== userId) {
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

  // --------------------------------------------------------- notifying

  private async announceResponse(
    row: HydratedCoachInvitation,
    type: NotificationType,
  ): Promise<void> {
    // The responder is the recipient, i.e. the side that didn't send it.
    const respondedByCoach =
      row.invitation.type === CoachInvitationType.CLUB_TO_COACH;
    await this.announce(
      row,
      row.invitation.senderUserId,
      type,
      respondedByCoach ? 'coach' : 'club',
    );
  }

  // After the fact, and never allowed to fail the transition it announces.
  private async announce(
    row: HydratedCoachInvitation,
    userId: Types.ObjectId,
    type: NotificationType,
    actor: 'club' | 'coach',
  ): Promise<void> {
    const params: NotificationParams =
      actor === 'club'
        ? {
            actorRole: NotificationActorRole.CLUB,
            actorName: row.clubProfile?.name,
            actorProfileId: row.clubProfile?._id.toString(),
            actorPublicCode: row.clubProfile?.publicCode,
          }
        : {
            actorRole: NotificationActorRole.COACH,
            actorName: coachDisplayName(row.coachProfile),
            actorProfileId: row.coachProfile?._id.toString(),
            actorPublicCode: row.coachProfile?.publicCode,
          };
    try {
      await this.notifications.emit({
        userId,
        type,
        entityType: NotificationEntityType.COACH_INVITATION,
        entityId: row.invitation._id,
        params,
      });
    } catch {
      this.logger.error('Failed to announce a coach invitation event.');
    }
  }
}
