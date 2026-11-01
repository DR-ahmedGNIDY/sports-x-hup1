import {
  BadRequestException,
  ForbiddenException,
  HttpException,
} from '@nestjs/common';
import { Types } from 'mongoose';
import { PlayerSubscriptionsService } from './player-subscriptions.service';
import { SubscriptionPlan } from './schemas/player-subscription.schema';
import {
  addDays,
  statusFor,
  SubscriptionStatus,
  todayInAcademy,
} from './subscription-dates';

const CLUB = new Types.ObjectId().toString();
const PLAYER = new Types.ObjectId().toString();

describe('subscription dates', () => {
  it('reads a subscription ending today as about to expire, not expired', () => {
    expect(statusFor('2026-11-10', '2026-11-10')).toBe(
      SubscriptionStatus.EXPIRING,
    );
    expect(statusFor('2026-11-13', '2026-11-10')).toBe(
      SubscriptionStatus.EXPIRING,
    );
    expect(statusFor('2026-11-14', '2026-11-10')).toBe(
      SubscriptionStatus.ACTIVE,
    );
    expect(statusFor('2026-11-09', '2026-11-10')).toBe(
      SubscriptionStatus.EXPIRED,
    );
    expect(statusFor(undefined, '2026-11-10')).toBe(SubscriptionStatus.NONE);
  });

  it('crosses month and year ends', () => {
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2027-03-01', -1)).toBe('2027-02-28');
  });

  it('uses the Cairo calendar, not the server clock', () => {
    // 23:30 UTC on the 10th is already the 11th in Cairo.
    expect(todayInAcademy(new Date('2026-11-10T23:30:00Z'))).toBe('2026-11-11');
  });
});

function subscriptionDoc(fields: Record<string, unknown> = {}) {
  return {
    _id: new Types.ObjectId(),
    clubUserId: new Types.ObjectId(CLUB),
    playerUserId: new Types.ObjectId(PLAYER),
    plan: SubscriptionPlan.MONTHLY,
    startDate: '2026-10-01',
    endDate: '2026-10-31',
    amountMinor: 50000,
    paidMinor: 50000,
    save: jest.fn().mockImplementation(function (this: unknown) {
      return Promise.resolve(this);
    }),
    ...fields,
  };
}

function buildService(options: { roster?: string[] } = {}) {
  const subscriptionModel = {
    create: jest.fn().mockImplementation((doc) => Promise.resolve(doc)),
    find: jest.fn(),
    findOne: jest.fn(),
    exists: jest.fn().mockResolvedValue(null),
    updateOne: jest.fn().mockResolvedValue({ modifiedCount: 1 }),
    deleteOne: jest.fn().mockResolvedValue({}),
  };
  const clubPlayers = {
    rosterUserIds: jest.fn().mockResolvedValue(options.roster ?? [PLAYER]),
    dialCodeFor: jest.fn().mockResolvedValue(undefined),
  };
  const players = {
    findManyByUserIds: jest.fn().mockResolvedValue([]),
    getOrCreateForUser: jest.fn().mockResolvedValue({
      _id: new Types.ObjectId(),
      firstName: 'Omar',
      lastName: 'Salah',
      contact: { phone: '01012345678' },
    }),
  };
  const clubs = {
    getOrCreateForUser: jest.fn().mockResolvedValue({ name: 'Zamalek Academy' }),
  };
  const users = { findByIdOrThrow: jest.fn().mockResolvedValue({}) };
  const notifications = {
    emit: jest.fn().mockResolvedValue(null),
    emitFresh: jest.fn().mockResolvedValue(null),
  };
  const service = new PlayerSubscriptionsService(
    subscriptionModel as never,
    clubPlayers as never,
    players as never,
    clubs as never,
    users as never,
    notifications as never,
  );
  return { service, subscriptionModel, clubPlayers, notifications };
}

const createDto = {
  playerUserId: PLAYER,
  plan: SubscriptionPlan.MONTHLY,
  startDate: '2026-11-01',
  endDate: '2026-11-30',
  amountMinor: 50000,
};

describe('PlayerSubscriptionsService', () => {
  describe('create', () => {
    it('refuses a player who is not on the club roster', async () => {
      const { service, subscriptionModel } = buildService({ roster: [] });

      await expect(service.create(CLUB, createDto)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(subscriptionModel.create).not.toHaveBeenCalled();
    });

    it('refuses an end date before the start', async () => {
      const { service } = buildService();

      await expect(
        service.create(CLUB, { ...createDto, endDate: '2026-10-31' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('refuses a payment larger than the amount', async () => {
      const { service } = buildService();

      await expect(
        service.create(CLUB, { ...createDto, paidMinor: 60000 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('renew', () => {
    it('starts the day after the old end, for the same length, unpaid', async () => {
      const { service, subscriptionModel } = buildService();
      subscriptionModel.findOne.mockResolvedValue(subscriptionDoc());

      const renewed = await service.renew(CLUB, new Types.ObjectId().toString());

      expect(renewed).toMatchObject({
        startDate: '2026-11-01',
        endDate: '2026-12-01',
        amountMinor: 50000,
        paidMinor: 0,
      });
    });
  });

  describe('remind', () => {
    it('notifies the player in the name of the club', async () => {
      const { service, subscriptionModel, notifications } = buildService();
      const latest = subscriptionDoc();
      subscriptionModel.findOne.mockReturnValue({
        sort: jest.fn().mockResolvedValue(latest),
      });

      await service.remind(CLUB, PLAYER);

      expect(notifications.emitFresh).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: PLAYER,
          type: 'SUBSCRIPTION_REMINDER',
          params: expect.objectContaining({ actorName: 'Zamalek Academy' }),
        }),
      );
      expect(latest.save).toHaveBeenCalled();
    });

    it('allows one reminder a day', async () => {
      const { service, subscriptionModel, notifications } = buildService();
      subscriptionModel.findOne.mockReturnValue({
        sort: jest
          .fn()
          .mockResolvedValue(subscriptionDoc({ lastReminderAt: new Date() })),
      });

      await expect(service.remind(CLUB, PLAYER)).rejects.toBeInstanceOf(
        HttpException,
      );
      expect(notifications.emitFresh).not.toHaveBeenCalled();
    });
  });

  describe('announceExpiries', () => {
    const today = '2026-11-28';

    it('tells both the club and the player once a subscription nears its end', async () => {
      const { service, subscriptionModel, notifications } = buildService();
      subscriptionModel.find
        .mockResolvedValueOnce([subscriptionDoc({ endDate: '2026-11-30' })])
        .mockResolvedValueOnce([]);

      await service.announceExpiries(today);

      expect(notifications.emit).toHaveBeenCalledTimes(2);
      expect(notifications.emit).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: CLUB,
          type: 'SUBSCRIPTION_EXPIRING',
          params: expect.objectContaining({
            actorName: 'Omar Salah',
            subscriptionPlayerUserId: PLAYER,
          }),
        }),
      );
      expect(notifications.emit).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: PLAYER,
          params: expect.objectContaining({ actorName: 'Zamalek Academy' }),
        }),
      );
    });

    it('stays quiet about a period that was already renewed', async () => {
      const { service, subscriptionModel, notifications } = buildService();
      subscriptionModel.find
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([subscriptionDoc({ endDate: '2026-11-27' })]);
      subscriptionModel.exists.mockResolvedValue({ _id: 'next-period' });

      await service.announceExpiries(today);

      expect(notifications.emit).not.toHaveBeenCalled();
    });

    it('stays quiet when another run already claimed it', async () => {
      const { service, subscriptionModel, notifications } = buildService();
      subscriptionModel.find
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([subscriptionDoc({ endDate: '2026-11-27' })]);
      subscriptionModel.updateOne.mockResolvedValue({ modifiedCount: 0 });

      await service.announceExpiries(today);

      expect(notifications.emit).not.toHaveBeenCalled();
    });

    it('keeps going past a row that fails', async () => {
      const { service, subscriptionModel, notifications } = buildService();
      subscriptionModel.find
        .mockResolvedValueOnce([
          subscriptionDoc({ endDate: '2026-11-29' }),
          subscriptionDoc({ endDate: '2026-11-30' }),
        ])
        .mockResolvedValueOnce([]);
      subscriptionModel.exists
        .mockRejectedValueOnce(new Error('mongo is down'))
        .mockResolvedValueOnce(null);

      await expect(service.announceExpiries(today)).resolves.toBeUndefined();
      expect(notifications.emit).toHaveBeenCalledTimes(2);
    });
  });
});
