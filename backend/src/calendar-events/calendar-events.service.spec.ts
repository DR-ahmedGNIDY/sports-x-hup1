import { BadRequestException } from '@nestjs/common';
import { CalendarEventsService } from './calendar-events.service';
import {
  CalendarEventRecurrence,
  CalendarEventType,
} from './schemas/calendar-event.schema';

const CLUB_USER = '507f1f77bcf86cd799439099';
const VALID_ID = '507f1f77bcf86cd799439011';
const PLAYER_ID_1 = '507f1f77bcf86cd799439012';
const PLAYER_ID_2 = '507f1f77bcf86cd799439013';

function buildService(
  overrides: {
    insertManyResult?: unknown;
    findByIdResult?: Record<string, unknown> | null;
    playerProfiles?: Record<string, unknown>[];
  } = {},
) {
  const savedDocs: Record<string, unknown>[] = [];
  const baseEvent = {
    _id: VALID_ID,
    clubUserId: CLUB_USER,
    type: CalendarEventType.MATCH,
    date: new Date(Date.now() - 60 * 60 * 1000),
    startTime: '00:00',
    endTime: '01:00',
    participants: [],
    matchStats: [],
    save: jest.fn().mockImplementation(function (
      this: Record<string, unknown>,
    ) {
      savedDocs.push(this);
      return Promise.resolve(this);
    }),
  };

  const eventModel = {
    insertMany: jest
      .fn()
      .mockResolvedValue(overrides.insertManyResult ?? [{ _id: VALID_ID }]),
    findById: jest
      .fn()
      .mockResolvedValue(
        overrides.findByIdResult === undefined
          ? { ...baseEvent }
          : overrides.findByIdResult,
      ),
    find: jest.fn().mockReturnValue({
      sort: jest.fn().mockResolvedValue([]),
    }),
    deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
  };

  const clubManagedPlayerModel = {
    find: jest.fn().mockResolvedValue([]),
  };

  const playersService = {
    getOrCreateForUser: jest
      .fn()
      .mockResolvedValue({ _id: 'player-profile-1' }),
    findManyByUserIds: jest.fn().mockResolvedValue([]),
    findPublicByIdOrThrow: jest.fn().mockImplementation((id: string) =>
      Promise.resolve(
        (overrides.playerProfiles ?? []).find((p) => p._id === id) ?? {
          _id: id,
          userId: `user-${id}`,
          position: 'GK',
        },
      ),
    ),
  };

  const clubsService = {
    getOrCreateForUser: jest.fn().mockResolvedValue({
      _id: 'club-profile-1',
      name: 'Al Ahly',
      publicCode: 'CLB-000001',
    }),
  };

  const notifications = {
    emit: jest.fn().mockResolvedValue({ _id: 'notification-1' }),
  };

  const service = new CalendarEventsService(
    eventModel as never,
    clubManagedPlayerModel as never,
    playersService as never,
    clubsService as never,
    notifications as never,
  );

  return {
    service,
    eventModel,
    clubManagedPlayerModel,
    playersService,
    notifications,
  };
}

describe('CalendarEventsService', () => {
  describe('create', () => {
    it('materializes weekly recurrence into ~3 months of sibling occurrences', async () => {
      const { service, eventModel } = buildService();
      await service.create(CLUB_USER, {
        type: CalendarEventType.TRAINING,
        date: '2026-01-01',
        startTime: '18:00',
        endTime: '19:00',
        location: 'Main pitch',
        recurrence: CalendarEventRecurrence.WEEKLY,
      });
      const inserted = eventModel.insertMany.mock.calls[0][0];
      expect(inserted).toHaveLength(13);
      expect(inserted[0].recurrenceGroupId).toBeDefined();
      expect(inserted[0].recurrenceGroupId).toEqual(
        inserted[1].recurrenceGroupId,
      );
    });

    it('materializes monthly recurrence into 3 occurrences', async () => {
      const { service, eventModel } = buildService();
      await service.create(CLUB_USER, {
        type: CalendarEventType.TRAINING,
        date: '2026-01-01',
        startTime: '18:00',
        endTime: '19:00',
        location: 'Main pitch',
        recurrence: CalendarEventRecurrence.MONTHLY,
      });
      expect(eventModel.insertMany.mock.calls[0][0]).toHaveLength(3);
    });

    it('creates a single document with no recurrenceGroupId for NONE', async () => {
      const { service, eventModel } = buildService();
      await service.create(CLUB_USER, {
        type: CalendarEventType.TRAINING,
        date: '2026-01-01',
        startTime: '18:00',
        endTime: '19:00',
        location: 'Main pitch',
        recurrence: CalendarEventRecurrence.NONE,
      });
      const inserted = eventModel.insertMany.mock.calls[0][0];
      expect(inserted).toHaveLength(1);
      expect(inserted[0].recurrenceGroupId).toBeUndefined();
    });
  });

  describe('updateRoster', () => {
    it('sets confirmedAt and emits one notification per participant', async () => {
      const { service, notifications } = buildService({
        playerProfiles: [
          { _id: PLAYER_ID_1, userId: 'user-1', position: 'GK' },
          { _id: PLAYER_ID_2, userId: 'user-2', position: 'ST' },
        ],
      });

      const event = await service.updateRoster(CLUB_USER, VALID_ID, {
        playerIds: [PLAYER_ID_1, PLAYER_ID_2],
      });

      expect(event.confirmedAt).toBeInstanceOf(Date);
      expect(event.participants).toHaveLength(2);
      expect(notifications.emit).toHaveBeenCalledTimes(2);
    });
  });

  describe('updateStats', () => {
    it('rejects stats for a non-MATCH event', async () => {
      const { service } = buildService({
        findByIdResult: {
          _id: VALID_ID,
          clubUserId: CLUB_USER,
          type: CalendarEventType.TRAINING,
          date: new Date(Date.now() - 60 * 60 * 1000),
          startTime: '00:00',
          save: jest.fn().mockResolvedValue(undefined),
        },
      });

      await expect(
        service.updateStats(CLUB_USER, VALID_ID, { entries: [] }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects stats before the event start time', async () => {
      const future = new Date(Date.now() + 60 * 60 * 1000);
      const { service } = buildService({
        findByIdResult: {
          _id: VALID_ID,
          clubUserId: CLUB_USER,
          type: CalendarEventType.MATCH,
          date: future,
          startTime: `${future.getHours().toString().padStart(2, '0')}:${future
            .getMinutes()
            .toString()
            .padStart(2, '0')}`,
          save: jest.fn().mockResolvedValue(undefined),
        },
      });

      await expect(
        service.updateStats(CLUB_USER, VALID_ID, { entries: [] }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('accepts stats once the event has started', async () => {
      const past = new Date(Date.now() - 60 * 60 * 1000);
      const saveMock = jest.fn().mockResolvedValue(undefined);
      const { service } = buildService({
        findByIdResult: {
          _id: VALID_ID,
          clubUserId: CLUB_USER,
          type: CalendarEventType.MATCH,
          date: past,
          startTime: `${past.getHours().toString().padStart(2, '0')}:${past
            .getMinutes()
            .toString()
            .padStart(2, '0')}`,
          save: saveMock,
        },
      });

      await service.updateStats(CLUB_USER, VALID_ID, {
        entries: [
          {
            playerId: PLAYER_ID_1,
            goals: 1,
            assists: 0,
            chancesCreated: 2,
            keyPasses: 3,
            keyDefensiveActions: 0,
            saves: 0,
          },
        ],
      });
      expect(saveMock).toHaveBeenCalled();
    });
  });
});
