import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ClubPlayersService } from '../club-players/club-players.service';
import { ClubsService } from '../clubs/clubs.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  NotificationActorRole,
  NotificationEntityType,
  NotificationType,
} from '../notifications/schemas/notification.schema';
import { profilePhotoUrl } from '../players/players.mapper';
import { PlayersService } from '../players/players.service';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { UsersService } from '../users/users.service';
import {
  CreateSubscriptionDto,
  UpdateSubscriptionDto,
} from './dto/upsert-subscription.dto';
import {
  PlayerSubscription,
  PlayerSubscriptionDocument,
} from './schemas/player-subscription.schema';
import {
  addDays,
  daysBetween,
  EXPIRING_SOON_DAYS,
  statusFor,
  SubscriptionStatus,
  todayInAcademy,
} from './subscription-dates';

// Ids are stored as ObjectIds (see create), and this codebase does not
// rely on Mongoose casting a string filter to match them — every query
// below converts first.
const oid = (id: string) => new Types.ObjectId(id);

/** How far back the daily job looks for expiries it has not announced. */
const EXPIRED_LOOKBACK_DAYS = 7;

export interface RosterSubscriptionRow {
  playerUserId: string;
  firstName?: string;
  lastName?: string;
  photoUrl?: string;
  status: SubscriptionStatus;
  current: PlayerSubscriptionDocument | null;
}

export interface ClubSubscriptionsOverview {
  today: string;
  counts: Record<SubscriptionStatus, number> & { unpaid: number };
  items: RosterSubscriptionRow[];
}

function playerName(profile?: PlayerProfileDocument | null): string | undefined {
  const name = [profile?.firstName, profile?.lastName]
    .filter(Boolean)
    .join(' ')
    .trim();
  return name || undefined;
}

@Injectable()
export class PlayerSubscriptionsService {
  private readonly logger = new Logger(PlayerSubscriptionsService.name);

  constructor(
    @InjectModel(PlayerSubscription.name)
    private readonly subscriptionModel: Model<PlayerSubscription>,
    private readonly clubPlayers: ClubPlayersService,
    private readonly players: PlayersService,
    private readonly clubs: ClubsService,
    private readonly users: UsersService,
    private readonly notifications: NotificationsService,
  ) {}

  // ---------------------------------------------------------------- club

  /**
   * Every player on the roster with the state of their latest subscription.
   * Not paginated: a club's roster is bounded by what the club itself built,
   * and the filter chips need counts over all of it.
   */
  async overviewForClub(
    clubId: string,
    filter?: SubscriptionStatus,
  ): Promise<ClubSubscriptionsOverview> {
    const today = todayInAcademy();
    const userIds = await this.clubPlayers.rosterUserIds(clubId);
    const [profiles, latest] = await Promise.all([
      userIds.length ? this.players.findManyByUserIds(userIds) : [],
      this.latestByPlayer(clubId, userIds),
    ]);
    const profileByUser = new Map(
      profiles.map((p) => [p.userId.toString(), p]),
    );

    const counts = {
      [SubscriptionStatus.ACTIVE]: 0,
      [SubscriptionStatus.EXPIRING]: 0,
      [SubscriptionStatus.EXPIRED]: 0,
      [SubscriptionStatus.NONE]: 0,
      unpaid: 0,
    };
    const rows: RosterSubscriptionRow[] = userIds.map((userId) => {
      const current = latest.get(userId) ?? null;
      const status = statusFor(current?.endDate, today);
      counts[status] += 1;
      if (current && current.paidMinor < current.amountMinor) counts.unpaid += 1;
      const profile = profileByUser.get(userId);
      return {
        playerUserId: userId,
        firstName: profile?.firstName,
        lastName: profile?.lastName,
        photoUrl: profile ? profilePhotoUrl(profile) : undefined,
        status,
        current,
      };
    });

    // Most urgent first: who needs chasing, then who has nothing at all.
    const order = [
      SubscriptionStatus.EXPIRED,
      SubscriptionStatus.EXPIRING,
      SubscriptionStatus.NONE,
      SubscriptionStatus.ACTIVE,
    ];
    const items = rows
      .filter((row) => !filter || row.status === filter)
      .sort(
        (a, b) =>
          order.indexOf(a.status) - order.indexOf(b.status) ||
          (a.current?.endDate ?? '').localeCompare(b.current?.endDate ?? ''),
      );
    return { today, counts, items };
  }

  /** One player's whole history at this club, plus how to reach them. */
  async playerDetailForClub(clubId: string, playerUserId: string) {
    await this.requireOnRoster(clubId, playerUserId);
    const today = todayInAcademy();
    const [profile, history, phone] = await Promise.all([
      this.players.getOrCreateForUser(playerUserId),
      this.subscriptionModel
        .find({ clubUserId: oid(clubId), playerUserId: oid(playerUserId) })
        .sort({ endDate: -1 }),
      this.whatsAppPhoneFor(clubId, playerUserId),
    ]);
    return {
      playerUserId,
      firstName: profile.firstName,
      lastName: profile.lastName,
      photoUrl: profilePhotoUrl(profile),
      whatsAppPhone: phone,
      status: statusFor(history[0]?.endDate, today),
      history,
    };
  }

  async create(
    clubId: string,
    dto: CreateSubscriptionDto,
  ): Promise<PlayerSubscriptionDocument> {
    await this.requireOnRoster(clubId, dto.playerUserId);
    this.assertValid(dto.startDate, dto.endDate, dto.amountMinor, dto.paidMinor);
    return this.subscriptionModel.create({
      clubUserId: new Types.ObjectId(clubId),
      playerUserId: new Types.ObjectId(dto.playerUserId),
      plan: dto.plan,
      startDate: dto.startDate,
      endDate: dto.endDate,
      amountMinor: dto.amountMinor,
      paidMinor: dto.paidMinor ?? 0,
      notes: dto.notes?.trim() || undefined,
    });
  }

  async update(
    clubId: string,
    id: string,
    dto: UpdateSubscriptionDto,
  ): Promise<PlayerSubscriptionDocument> {
    const subscription = await this.requireOwned(clubId, id);
    const next = {
      startDate: dto.startDate ?? subscription.startDate,
      endDate: dto.endDate ?? subscription.endDate,
      amountMinor: dto.amountMinor ?? subscription.amountMinor,
      paidMinor: dto.paidMinor ?? subscription.paidMinor,
    };
    this.assertValid(
      next.startDate,
      next.endDate,
      next.amountMinor,
      next.paidMinor,
    );

    // A new end date is a new expiry to announce. Clearing the flags is
    // what lets the daily job tell everyone again.
    if (dto.endDate && dto.endDate !== subscription.endDate) {
      subscription.expiringNotifiedAt = undefined;
      subscription.expiredNotifiedAt = undefined;
    }
    Object.assign(subscription, next);
    if (dto.plan) subscription.plan = dto.plan;
    if (dto.notes !== undefined) {
      subscription.notes = dto.notes.trim() || undefined;
    }
    return subscription.save();
  }

  /**
   * The next period, back to back with this one: same plan, same length,
   * same price, nothing paid yet.
   */
  async renew(clubId: string, id: string): Promise<PlayerSubscriptionDocument> {
    const previous = await this.requireOwned(clubId, id);
    const length = daysBetween(previous.startDate, previous.endDate);
    const startDate = addDays(previous.endDate, 1);
    return this.subscriptionModel.create({
      clubUserId: previous.clubUserId,
      playerUserId: previous.playerUserId,
      plan: previous.plan,
      startDate,
      endDate: addDays(startDate, length),
      amountMinor: previous.amountMinor,
      paidMinor: 0,
    });
  }

  async remove(clubId: string, id: string): Promise<void> {
    const subscription = await this.requireOwned(clubId, id);
    await this.subscriptionModel.deleteOne({ _id: subscription._id });
  }

  /**
   * The club's "please renew" nudge, as an in-app notification (and a push,
   * if the player enabled them). One a day per player, so a busy afternoon
   * of chasing payments cannot become a stream of buzzes.
   */
  async remind(clubId: string, playerUserId: string): Promise<void> {
    await this.requireOnRoster(clubId, playerUserId);
    const latest = await this.subscriptionModel
      .findOne({ clubUserId: oid(clubId), playerUserId: oid(playerUserId) })
      .sort({ endDate: -1 });
    if (!latest) {
      throw new NotFoundException('This player has no subscription to renew.');
    }

    const today = todayInAcademy();
    if (latest.lastReminderAt && todayInAcademy(latest.lastReminderAt) === today) {
      throw new HttpException(
        'This player was already reminded today.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    latest.lastReminderAt = new Date();
    await latest.save();

    const club = await this.clubs.getOrCreateForUser(clubId);
    await this.notifications.emitFresh({
      userId: playerUserId,
      type: NotificationType.SUBSCRIPTION_REMINDER,
      entityType: NotificationEntityType.PLAYER_SUBSCRIPTION,
      entityId: latest._id,
      params: {
        actorName: club.name,
        actorRole: NotificationActorRole.CLUB,
        subscriptionEndDate: latest.endDate,
      },
    });
  }

  // -------------------------------------------------------------- player

  /** The player's own latest subscription, at whichever club holds it. */
  async mine(playerUserId: string) {
    const latest = await this.subscriptionModel
      .findOne({ playerUserId: oid(playerUserId) })
      .sort({ endDate: -1 });
    if (!latest) return { status: SubscriptionStatus.NONE, current: null };
    const club = await this.clubs.getOrCreateForUser(
      latest.clubUserId.toString(),
    );
    return {
      status: statusFor(latest.endDate, todayInAcademy()),
      clubName: club.name,
      current: latest,
    };
  }

  // ----------------------------------------------------------- daily job

  /**
   * Announces every subscription that has just entered its last
   * [EXPIRING_SOON_DAYS] days, or has just ended, to its club and its
   * player. Only a player's *latest* subscription counts — a period that
   * was already renewed has nothing to warn about.
   *
   * Never throws: one bad row is a log line, not a skipped run.
   */
  async announceExpiries(today: string = todayInAcademy()): Promise<void> {
    const soon = addDays(today, EXPIRING_SOON_DAYS);
    const since = addDays(today, -EXPIRED_LOOKBACK_DAYS);

    const [expiring, expired] = await Promise.all([
      this.subscriptionModel.find({
        endDate: { $gte: today, $lte: soon },
        expiringNotifiedAt: { $exists: false },
      }),
      this.subscriptionModel.find({
        endDate: { $gte: since, $lt: today },
        expiredNotifiedAt: { $exists: false },
      }),
    ]);

    for (const subscription of expiring) {
      await this.announce(subscription, 'expiring');
    }
    for (const subscription of expired) {
      await this.announce(subscription, 'expired');
    }
  }

  private async announce(
    subscription: PlayerSubscriptionDocument,
    kind: 'expiring' | 'expired',
  ): Promise<void> {
    const flag = kind === 'expiring' ? 'expiringNotifiedAt' : 'expiredNotifiedAt';
    try {
      const renewed = await this.subscriptionModel.exists({
        clubUserId: subscription.clubUserId,
        playerUserId: subscription.playerUserId,
        endDate: { $gt: subscription.endDate },
      });

      // Claimed before sending: of two overlapping runs, only the one whose
      // update matched goes on to notify.
      const claimed = await this.subscriptionModel.updateOne(
        { _id: subscription._id, [flag]: { $exists: false } },
        { $set: { [flag]: new Date() } },
      );
      if (renewed || claimed.modifiedCount === 0) return;

      const clubId = subscription.clubUserId.toString();
      const playerId = subscription.playerUserId.toString();
      const [club, profile] = await Promise.all([
        this.clubs.getOrCreateForUser(clubId),
        this.players.getOrCreateForUser(playerId),
      ]);
      const type =
        kind === 'expiring'
          ? NotificationType.SUBSCRIPTION_EXPIRING
          : NotificationType.SUBSCRIPTION_EXPIRED;
      const base = {
        type,
        entityType: NotificationEntityType.PLAYER_SUBSCRIPTION,
        entityId: subscription._id,
      };

      await Promise.all([
        // To the club, naming the player.
        this.notifications.emit({
          ...base,
          userId: clubId,
          params: {
            actorName: playerName(profile),
            actorRole: NotificationActorRole.PLAYER,
            actorProfileId: profile._id.toString(),
            subscriptionEndDate: subscription.endDate,
            subscriptionPlayerUserId: playerId,
          },
        }),
        // To the player, naming the club.
        this.notifications.emit({
          ...base,
          userId: playerId,
          params: {
            actorName: club.name,
            actorRole: NotificationActorRole.CLUB,
            subscriptionEndDate: subscription.endDate,
          },
        }),
      ]);
    } catch {
      this.logger.error(
        `Failed to announce subscription ${subscription._id.toString()} (${kind}).`,
      );
    }
  }

  // ------------------------------------------------------------- helpers

  private async latestByPlayer(
    clubId: string,
    userIds: string[],
  ): Promise<Map<string, PlayerSubscriptionDocument>> {
    if (userIds.length === 0) return new Map();
    const all = await this.subscriptionModel
      .find({
        clubUserId: oid(clubId),
        playerUserId: { $in: userIds.map(oid) },
      })
      .sort({ endDate: -1 });
    const latest = new Map<string, PlayerSubscriptionDocument>();
    for (const subscription of all) {
      const key = subscription.playerUserId.toString();
      if (!latest.has(key)) latest.set(key, subscription);
    }
    return latest;
  }

  /**
   * The number WhatsApp needs: international, digits only. A profile's own
   * WhatsApp number wins, then its phone, then the login phone a club-created
   * player has. A local number ("010…") is completed with the dial code the
   * club registered the player under, or Egypt's.
   */
  private async whatsAppPhoneFor(
    clubId: string,
    playerUserId: string,
  ): Promise<string | null> {
    const [profile, user, dialCode] = await Promise.all([
      this.players.getOrCreateForUser(playerUserId),
      this.users.findByIdOrThrow(playerUserId),
      this.clubPlayers.dialCodeFor(clubId, playerUserId),
    ]);
    const raw =
      profile.contact?.whatsapp || profile.contact?.phone || user.phone || '';
    const trimmed = raw.trim();
    if (!trimmed) return null;
    if (trimmed.startsWith('+')) return trimmed.replace(/\D/g, '');
    const digits = trimmed.replace(/\D/g, '');
    if (digits.startsWith('00')) return digits.slice(2);
    if (digits.startsWith('0')) {
      const code = (dialCode || '+20').replace(/\D/g, '');
      return code + digits.slice(1);
    }
    return digits;
  }

  private async requireOnRoster(clubId: string, playerUserId: string) {
    const roster = await this.clubPlayers.rosterUserIds(clubId);
    if (!roster.includes(playerUserId)) {
      throw new ForbiddenException('This player is not in your club.');
    }
  }

  private async requireOwned(
    clubId: string,
    id: string,
  ): Promise<PlayerSubscriptionDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Subscription not found.');
    }
    const subscription = await this.subscriptionModel.findOne({
      _id: oid(id),
      clubUserId: oid(clubId),
    });
    if (!subscription) throw new NotFoundException('Subscription not found.');
    return subscription;
  }

  private assertValid(
    startDate: string,
    endDate: string,
    amountMinor: number,
    paidMinor = 0,
  ): void {
    if (endDate < startDate) {
      throw new BadRequestException('endDate must not be before startDate.');
    }
    if (paidMinor > amountMinor) {
      throw new BadRequestException('paidMinor cannot exceed amountMinor.');
    }
  }
}
