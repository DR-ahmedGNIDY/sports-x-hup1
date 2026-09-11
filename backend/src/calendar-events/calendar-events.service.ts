import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  ClubManagedPlayer,
  ClubManagedPlayerDocument,
} from '../club-players/schemas/club-managed-player.schema';
import {
  NotificationActorRole,
  NotificationEntityType,
  NotificationType,
} from '../notifications/schemas/notification.schema';
import {
  ClubMembership,
  MembershipStatus,
} from '../invitations/schemas/club-membership.schema';
import { NotificationsService } from '../notifications/notifications.service';
import { ClubsService } from '../clubs/clubs.service';
import { PlayersService } from '../players/players.service';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto';
import { UpdateRosterDto } from './dto/update-roster.dto';
import { UpdateStatsDto } from './dto/update-stats.dto';
import {
  CalendarEvent,
  CalendarEventDocument,
  CalendarEventRecurrence,
  CalendarEventType,
} from './schemas/calendar-event.schema';

// ~3 months of sibling occurrences for a recurring event, materialized at
// creation time as independent documents (see the plan's decision on this).
const WEEKLY_OCCURRENCES = 13; // ~13 weeks ≈ 3 months
const MONTHLY_OCCURRENCES = 3;

export interface RosterPoolGroup {
  birthYear: number | null;
  players: PlayerProfileDocument[];
}

@Injectable()
export class CalendarEventsService {
  private readonly logger = new Logger(CalendarEventsService.name);

  constructor(
    @InjectModel(CalendarEvent.name)
    private readonly eventModel: Model<CalendarEvent>,
    // Registered directly by CalendarEventsModule, same rationale as
    // InvitationsModule: this only ever reads the ownership rows to build
    // the roster pool, and importing ClubPlayersModule for that would
    // couple two independent features.
    @InjectModel(ClubManagedPlayer.name)
    private readonly clubManagedPlayerModel: Model<ClubManagedPlayer>,
    @InjectModel(ClubMembership.name)
    private readonly membershipModel: Model<ClubMembership>,
    private readonly playersService: PlayersService,
    private readonly clubsService: ClubsService,
    private readonly notifications: NotificationsService,
  ) {}

  private async safely(announce: () => Promise<unknown>): Promise<void> {
    try {
      await announce();
    } catch {
      this.logger.error('Failed to announce a calendar event notification.');
    }
  }

  // ------------------------------------------------------------- creating

  async create(
    clubUserId: string,
    dto: CreateCalendarEventDto,
  ): Promise<CalendarEventDocument[]> {
    const baseDate = new Date(dto.date);
    const occurrenceDates = this.materializeDates(baseDate, dto.recurrence);

    const recurrenceGroupId =
      occurrenceDates.length > 1 ? new Types.ObjectId() : undefined;

    const docs = occurrenceDates.map((date) => ({
      clubUserId: new Types.ObjectId(clubUserId),
      type: dto.type,
      customTypeName:
        dto.type === CalendarEventType.OTHER ? dto.customTypeName : undefined,
      date,
      startTime: dto.startTime,
      endTime: dto.endTime,
      location: dto.location,
      recurrence: dto.recurrence,
      recurrenceGroupId,
      opponentName:
        dto.type === CalendarEventType.MATCH ? dto.opponentName : undefined,
      rosterBirthYear: dto.rosterBirthYear ?? null,
      participants: [],
      matchStats: [],
    }));

    return this.eventModel.insertMany(docs);
  }

  private materializeDates(
    baseDate: Date,
    recurrence: CalendarEventRecurrence,
  ): Date[] {
    if (recurrence === CalendarEventRecurrence.WEEKLY) {
      return Array.from({ length: WEEKLY_OCCURRENCES }, (_, i) => {
        const d = new Date(baseDate);
        d.setUTCDate(d.getUTCDate() + i * 7);
        return d;
      });
    }
    if (recurrence === CalendarEventRecurrence.MONTHLY) {
      return Array.from({ length: MONTHLY_OCCURRENCES }, (_, i) => {
        const d = new Date(baseDate);
        d.setUTCMonth(d.getUTCMonth() + i);
        return d;
      });
    }
    return [baseDate];
  }

  // --------------------------------------------------------------- reading

  private monthRange(month: string): { start: Date; end: Date } {
    const [year, monthNum] = month.split('-').map(Number);
    const start = new Date(Date.UTC(year, monthNum - 1, 1));
    const end = new Date(Date.UTC(year, monthNum, 1));
    return { start, end };
  }

  async listForClub(
    clubUserId: string,
    month: string,
  ): Promise<CalendarEventDocument[]> {
    const { start, end } = this.monthRange(month);
    // `@Prop({ type: Types.ObjectId })` resolves to a Mixed path, so Mongoose
    // never casts a string filter here — it has to match the ObjectId that
    // create() stores, or the query silently finds nothing.
    return this.eventModel
      .find({
        clubUserId: new Types.ObjectId(clubUserId),
        date: { $gte: start, $lt: end },
      })
      .sort({ date: 1, startTime: 1 });
  }

  async listForPlayer(
    playerUserId: string,
    month: string,
  ): Promise<CalendarEventDocument[]> {
    const profile = await this.playersService.getOrCreateForUser(playerUserId);
    const { start, end } = this.monthRange(month);
    return this.eventModel
      .find({
        'participants.playerId': profile._id,
        date: { $gte: start, $lt: end },
      })
      .sort({ date: 1, startTime: 1 });
  }

  async findByIdForParty(
    userId: string,
    id: string,
    role: 'CLUB' | 'PLAYER',
  ): Promise<CalendarEventDocument> {
    const event = await this.requireById(id);
    if (role === 'CLUB') {
      if (event.clubUserId.toString() !== userId) {
        throw new ForbiddenException(
          'This event does not belong to your club.',
        );
      }
      return event;
    }
    const profile = await this.playersService.getOrCreateForUser(userId);
    const isParticipant = event.participants.some(
      (p) => p.playerId.toString() === profile._id.toString(),
    );
    if (!isParticipant) {
      throw new ForbiddenException('You are not part of this event.');
    }
    return event;
  }

  private async requireById(id: string): Promise<CalendarEventDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Event not found.');
    }
    const event = await this.eventModel.findById(id);
    if (!event) {
      throw new NotFoundException('Event not found.');
    }
    return event;
  }

  private async requireOwnedByClub(
    clubUserId: string,
    id: string,
  ): Promise<CalendarEventDocument> {
    const event = await this.requireById(id);
    if (event.clubUserId.toString() !== clubUserId) {
      throw new ForbiddenException('This event does not belong to your club.');
    }
    return event;
  }

  // ---------------------------------------------------------- roster pool

  async rosterPool(clubUserId: string, id: string): Promise<RosterPoolGroup[]> {
    const event = await this.requireOwnedByClub(clubUserId, id);
    const [ownerships, memberships] = await Promise.all([
      this.clubManagedPlayerModel.find({ clubId: clubUserId }),
      // A player who accepted an invitation is part of the squad too, even
      // though the club never created their account.
      this.membershipModel.find({
        clubUserId,
        status: MembershipStatus.ACTIVE,
      }),
    ]);
    const userIds = [
      ...new Set([
        ...ownerships.map((o) => o.userId.toString()),
        ...memberships.map((m) => m.playerUserId.toString()),
      ]),
    ];
    if (userIds.length === 0) return [];

    const profiles = await this.playersService.findManyByUserIds(userIds);
    const filtered =
      event.rosterBirthYear === null || event.rosterBirthYear === undefined
        ? profiles
        : profiles.filter(
            (p) =>
              p.dateOfBirth &&
              p.dateOfBirth.getUTCFullYear() === event.rosterBirthYear,
          );

    if (event.rosterBirthYear !== null && event.rosterBirthYear !== undefined) {
      return [{ birthYear: event.rosterBirthYear, players: filtered }];
    }

    // "All players" pool: grouped by birth year for the same picker UX the
    // club-players birth-year filter already offers.
    const groups = new Map<number | null, PlayerProfileDocument[]>();
    for (const profile of filtered) {
      const year = profile.dateOfBirth
        ? profile.dateOfBirth.getUTCFullYear()
        : null;
      const bucket = groups.get(year) ?? [];
      bucket.push(profile);
      groups.set(year, bucket);
    }
    return [...groups.entries()]
      .sort((a, b) => (b[0] ?? 0) - (a[0] ?? 0))
      .map(([birthYear, players]) => ({ birthYear, players }));
  }

  // ------------------------------------------------------------ roster set

  async updateRoster(
    clubUserId: string,
    id: string,
    dto: UpdateRosterDto,
  ): Promise<CalendarEventDocument> {
    const event = await this.requireOwnedByClub(clubUserId, id);
    if (dto.playerIds.length === 0) {
      throw new BadRequestException('Select at least one player.');
    }

    const participants = await Promise.all(
      dto.playerIds.map(async (playerId) => {
        const profile =
          await this.playersService.findPublicByIdOrThrow(playerId);
        const overridePosition = dto.positions?.[playerId];
        return {
          playerId: profile._id,
          position: overridePosition ?? profile.position ?? undefined,
        };
      }),
    );

    event.participants = participants;
    event.confirmedAt = new Date();
    await event.save();

    const clubProfile = await this.clubsService.getOrCreateForUser(clubUserId);
    for (const participant of participants) {
      const profile = await this.playersService.findPublicByIdOrThrow(
        participant.playerId.toString(),
      );
      await this.safely(() =>
        this.notifications.emit({
          userId: profile.userId,
          type: NotificationType.EVENT_SCHEDULED,
          entityType: NotificationEntityType.CALENDAR_EVENT,
          entityId: event._id,
          params: {
            actorRole: NotificationActorRole.CLUB,
            actorName: clubProfile.name,
            actorProfileId: clubProfile._id.toString(),
            actorPublicCode: clubProfile.publicCode,
          },
        }),
      );
    }

    return event;
  }

  // ------------------------------------------------------------------ stats

  async updateStats(
    clubUserId: string,
    id: string,
    dto: UpdateStatsDto,
  ): Promise<CalendarEventDocument> {
    const event = await this.requireOwnedByClub(clubUserId, id);
    if (event.type !== CalendarEventType.MATCH) {
      throw new BadRequestException(
        'Match stats can only be recorded for MATCH events.',
      );
    }
    const startsAt = this.eventStartsAt(event);
    if (new Date() < startsAt) {
      throw new BadRequestException(
        'Match stats can only be recorded once the event has started.',
      );
    }

    event.matchStats = dto.entries.map((entry) => ({
      playerId: new Types.ObjectId(entry.playerId),
      goals: entry.goals,
      assists: entry.assists,
      chancesCreated: entry.chancesCreated,
      keyPasses: entry.keyPasses,
      keyDefensiveActions: entry.keyDefensiveActions,
      saves: entry.saves,
    }));
    await event.save();
    return event;
  }

  private eventStartsAt(event: CalendarEventDocument): Date {
    const [hours, minutes] = event.startTime.split(':').map(Number);
    const startsAt = new Date(event.date);
    startsAt.setHours(hours, minutes, 0, 0);
    return startsAt;
  }

  // ----------------------------------------------------------------- delete

  async remove(clubUserId: string, id: string): Promise<void> {
    const event = await this.requireOwnedByClub(clubUserId, id);
    await this.eventModel.deleteOne({ _id: event._id });
  }
}
