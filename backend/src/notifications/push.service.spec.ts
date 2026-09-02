import * as webPush from 'web-push';
import { PushService } from './push.service';

jest.mock('web-push', () => ({
  setVapidDetails: jest.fn(),
  sendNotification: jest.fn(),
}));

const sendNotification = webPush.sendNotification as jest.Mock;
const setVapidDetails = webPush.setVapidDetails as jest.Mock;

const payload = {
  notificationId: 'n1',
  type: 'INVITATION_RECEIVED',
  actorName: 'Al Ahly',
  actorRole: 'CLUB',
};

function subscription(endpoint: string) {
  return { endpoint, p256dh: 'key', auth: 'secret' };
}

function buildService(
  overrides: {
    configured?: boolean;
    subscriptions?: unknown[];
    find?: jest.Mock;
  } = {},
) {
  const configured = overrides.configured ?? true;
  const values: Record<string, string> = configured
    ? {
        VAPID_PUBLIC_KEY: 'public',
        VAPID_PRIVATE_KEY: 'private',
        VAPID_SUBJECT: 'mailto:ops@example.test',
      }
    : {};
  const config = { get: jest.fn((key: string) => values[key]) };

  const subscriptionModel = {
    find:
      overrides.find ??
      jest.fn().mockResolvedValue(overrides.subscriptions ?? []),
    updateOne: jest.fn().mockResolvedValue({ upsertedCount: 1 }),
    deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    deleteMany: jest.fn().mockResolvedValue({ deletedCount: 1 }),
  };

  return {
    service: new PushService(subscriptionModel as never, config as never),
    subscriptionModel,
    config,
  };
}

describe('PushService', () => {
  beforeEach(() => {
    sendNotification.mockReset().mockResolvedValue(undefined);
    setVapidDetails.mockReset();
  });

  describe('when VAPID keys are absent', () => {
    it('disables itself instead of failing to start', () => {
      const { service } = buildService({ configured: false });

      // Push is an addition on top of the durable in-app notification. A
      // dev machine or a deploy with no keys must still run.
      expect(service.isEnabled).toBe(false);
      expect(setVapidDetails).not.toHaveBeenCalled();
    });

    it('sends nothing, and does not even look for subscriptions', async () => {
      const { service, subscriptionModel } = buildService({
        configured: false,
        subscriptions: [subscription('https://push.test/a')],
      });

      await service.send('user-1', payload);

      expect(subscriptionModel.find).not.toHaveBeenCalled();
      expect(sendNotification).not.toHaveBeenCalled();
    });

    it('reports no public key, so the client skips its prompt', () => {
      const { service, config } = buildService({ configured: false });

      // A browser gives you one permission prompt. Spending it on a
      // capability the backend cannot deliver wastes it permanently.
      expect(service.publicKey(config as never)).toBeNull();
    });
  });

  describe('subscribe', () => {
    it('upserts on the endpoint, so re-subscribing does not duplicate', async () => {
      const { service, subscriptionModel } = buildService();

      await service.subscribe({
        userId: 'user-1',
        endpoint: 'https://push.test/a',
        p256dh: 'key',
        auth: 'secret',
      });

      const [filter, , options] = subscriptionModel.updateOne.mock.calls[0];
      // The endpoint *is* the subscription's identity — a second row for
      // the same browser would make every notification arrive twice.
      expect(filter).toEqual({ endpoint: 'https://push.test/a' });
      expect(options).toEqual({ upsert: true });
    });
  });

  describe('unsubscribe', () => {
    it('is scoped to the caller', async () => {
      const { service, subscriptionModel } = buildService();

      await service.unsubscribe('user-1', 'https://push.test/a');

      expect(subscriptionModel.deleteOne).toHaveBeenCalledWith({
        userId: 'user-1',
        endpoint: 'https://push.test/a',
      });
    });
  });

  describe('send', () => {
    it('reaches every browser the user has registered', async () => {
      const { service } = buildService({
        subscriptions: [
          subscription('https://push.test/a'),
          subscription('https://push.test/b'),
        ],
      });

      await service.send('user-1', payload);

      expect(sendNotification).toHaveBeenCalledTimes(2);
      const [, body] = sendNotification.mock.calls[0];
      expect(JSON.parse(body as string)).toEqual(payload);
    });

    it('prunes an endpoint the push service says is gone', async () => {
      const { service, subscriptionModel } = buildService({
        subscriptions: [
          subscription('https://push.test/dead'),
          subscription('https://push.test/alive'),
        ],
      });
      sendNotification.mockImplementation((sub: { endpoint: string }) =>
        sub.endpoint.endsWith('dead')
          ? Promise.reject({ statusCode: 410 })
          : Promise.resolve(undefined),
      );

      await service.send('user-1', payload);

      // 404/410 is the only signal a browser is gone for good. Without
      // pruning, the collection grows forever and every send spends
      // requests on endpoints that will never deliver again.
      expect(subscriptionModel.deleteMany).toHaveBeenCalledWith({
        endpoint: { $in: ['https://push.test/dead'] },
      });
    });

    it('keeps a subscription that failed transiently', async () => {
      const { service, subscriptionModel } = buildService({
        subscriptions: [subscription('https://push.test/a')],
      });
      sendNotification.mockRejectedValue({ statusCode: 429 });

      await service.send('user-1', payload);

      // A rate limit is not a dead browser.
      expect(subscriptionModel.deleteMany).not.toHaveBeenCalled();
    });

    it('never throws at its caller', async () => {
      const { service } = buildService({
        find: jest.fn().mockRejectedValue(new Error('database is gone')),
      });

      // The caller has already recorded the notification and committed an
      // invitation transition. A failed banner is worth a log line, never a
      // failed invitation.
      await expect(service.send('user-1', payload)).resolves.toBeUndefined();
    });

    it('does nothing when the user has no subscriptions', async () => {
      const { service } = buildService({ subscriptions: [] });

      await service.send('user-1', payload);

      expect(sendNotification).not.toHaveBeenCalled();
    });
  });
});
