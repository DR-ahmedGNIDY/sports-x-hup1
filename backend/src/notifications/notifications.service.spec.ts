import { NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import {
  NotificationActorRole,
  NotificationEntityType,
  NotificationType,
} from './schemas/notification.schema';

// The two properties this service exists to guarantee: emitting never
// breaks the thing being announced, and no query ever leaves the caller's
// own mailbox.

function buildService(
  overrides: {
    create?: jest.Mock;
    findOne?: jest.Mock;
    findOneAndUpdate?: jest.Mock;
    updateMany?: jest.Mock;
    countDocuments?: jest.Mock;
    items?: unknown[];
  } = {},
) {
  const notificationModel = {
    create: overrides.create ?? jest.fn().mockResolvedValue({ _id: 'n1' }),
    findOne: overrides.findOne ?? jest.fn().mockResolvedValue(null),
    findOneAndUpdate:
      overrides.findOneAndUpdate ?? jest.fn().mockResolvedValue(null),
    updateMany:
      overrides.updateMany ?? jest.fn().mockResolvedValue({ modifiedCount: 0 }),
    countDocuments: overrides.countDocuments ?? jest.fn().mockResolvedValue(0),
    find: jest.fn().mockReturnValue({
      sort: jest.fn().mockReturnValue({
        skip: jest.fn().mockReturnValue({
          limit: jest.fn().mockResolvedValue(overrides.items ?? []),
        }),
      }),
    }),
  };
  // Push is optional infrastructure and never throws at its caller; this
  // stands in for it so these tests are about the record, not the banner.
  const push = { send: jest.fn().mockResolvedValue(undefined) };

  return {
    service: new NotificationsService(
      notificationModel as never,
      push as never,
    ),
    notificationModel,
    push,
  };
}

const emitInput = {
  userId: 'user-1',
  type: NotificationType.INVITATION_RECEIVED,
  entityType: NotificationEntityType.INVITATION,
  entityId: 'invitation-1',
  params: { actorRole: NotificationActorRole.CLUB, actorName: 'Al Ahly' },
};

describe('NotificationsService', () => {
  describe('emit', () => {
    it('records the notification with its structured params', async () => {
      const { service, notificationModel } = buildService();

      await service.emit(emitInput);

      expect(notificationModel.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          type: NotificationType.INVITATION_RECEIVED,
          entityId: 'invitation-1',
          params: expect.objectContaining({ actorName: 'Al Ahly' }),
        }),
      );
    });

    it('treats a duplicate as a success and returns the existing row', async () => {
      const existing = { _id: 'already-there' };
      const { service, notificationModel } = buildService({
        create: jest.fn().mockRejectedValue({ code: 11000 }),
        findOne: jest.fn().mockResolvedValue(existing),
      });

      // The unique index is the dedupe rule: send, withdraw, re-send must
      // leave one unread row, not three.
      await expect(service.emit(emitInput)).resolves.toBe(existing);
      expect(notificationModel.findOne).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          entityId: 'invitation-1',
          type: NotificationType.INVITATION_RECEIVED,
        }),
      );
    });

    it('pushes on the creation branch, so a duplicate does not buzz twice', async () => {
      const { service, push } = buildService();

      await service.emit(emitInput);

      expect(push.send).toHaveBeenCalledWith(
        'user-1',
        expect.objectContaining({
          type: NotificationType.INVITATION_RECEIVED,
          actorName: 'Al Ahly',
        }),
      );
    });

    it('does not push when the row already existed', async () => {
      const { service, push } = buildService({
        create: jest.fn().mockRejectedValue({ code: 11000 }),
        findOne: jest.fn().mockResolvedValue({ _id: 'already-there' }),
      });

      await service.emit(emitInput);

      // The dedupe index silences the banner as well as the row: send,
      // withdraw, re-send buzzes a phone once.
      expect(push.send).not.toHaveBeenCalled();
    });

    it('never throws — a failed announcement must not fail the event', async () => {
      const { service } = buildService({
        create: jest.fn().mockRejectedValue(new Error('database is gone')),
      });

      // The caller has already committed an accept by this point. Throwing
      // here would turn a completed relationship into an error the user
      // sees, and roll nothing back.
      await expect(service.emit(emitInput)).resolves.toBeNull();
    });
  });

  describe('list', () => {
    it('scopes every read to the caller', async () => {
      const { service, notificationModel } = buildService();

      await service.list('user-1', {});

      expect(notificationModel.find).toHaveBeenCalledWith({ userId: 'user-1' });
      expect(notificationModel.countDocuments).toHaveBeenCalledWith({
        userId: 'user-1',
      });
    });

    it('filters to unread when asked, on the same scope', async () => {
      const { service, notificationModel } = buildService();

      await service.list('user-1', { unreadOnly: true });

      expect(notificationModel.find).toHaveBeenCalledWith({
        userId: 'user-1',
        readAt: { $exists: false },
      });
    });

    it('paginates rather than returning a whole history', async () => {
      const { service } = buildService();

      const result = await service.list('user-1', { page: 3 });

      expect(result.page).toBe(3);
      expect(result.pageSize).toBe(20);
    });
  });

  describe('unreadCount', () => {
    it('counts only the caller’s unread rows', async () => {
      const { service, notificationModel } = buildService({
        countDocuments: jest.fn().mockResolvedValue(4),
      });

      await expect(service.unreadCount('user-1')).resolves.toBe(4);
      expect(notificationModel.countDocuments).toHaveBeenCalledWith({
        userId: 'user-1',
        readAt: { $exists: false },
      });
    });
  });

  describe('markRead', () => {
    it('stamps readAt only while it is still unread', async () => {
      const { service, notificationModel } = buildService({
        findOneAndUpdate: jest.fn().mockResolvedValue({ _id: 'n1' }),
      });

      await service.markRead('user-1', '6a7d28ed58b00a8ab9a73199');

      const [filter] = notificationModel.findOneAndUpdate.mock.calls[0];
      // Re-reading an already-read notification must not rewrite when it
      // was first seen.
      expect(filter).toEqual({
        _id: '6a7d28ed58b00a8ab9a73199',
        userId: 'user-1',
        readAt: { $exists: false },
      });
    });

    it('is a no-op success when it was already read', async () => {
      const already = { _id: 'n1', readAt: new Date() };
      const { service } = buildService({
        findOneAndUpdate: jest.fn().mockResolvedValue(null),
        findOne: jest.fn().mockResolvedValue(already),
      });

      await expect(
        service.markRead('user-1', '6a7d28ed58b00a8ab9a73199'),
      ).resolves.toBe(already);
    });

    it('404s on someone else’s notification, disclosing nothing', async () => {
      const { service } = buildService({
        findOneAndUpdate: jest.fn().mockResolvedValue(null),
        findOne: jest.fn().mockResolvedValue(null),
      });

      await expect(
        service.markRead('user-1', '6a7d28ed58b00a8ab9a73199'),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects a malformed id without touching the database', async () => {
      const { service, notificationModel } = buildService();

      await expect(service.markRead('user-1', 'nonsense')).rejects.toThrow(
        NotFoundException,
      );
      expect(notificationModel.findOneAndUpdate).not.toHaveBeenCalled();
    });
  });

  describe('markAllRead', () => {
    it('clears the caller’s unread rows in one write', async () => {
      const { service, notificationModel } = buildService({
        updateMany: jest.fn().mockResolvedValue({ modifiedCount: 7 }),
      });

      await expect(service.markAllRead('user-1')).resolves.toBe(7);
      const [filter] = notificationModel.updateMany.mock.calls[0];
      expect(filter).toEqual({ userId: 'user-1', readAt: { $exists: false } });
    });
  });
});
