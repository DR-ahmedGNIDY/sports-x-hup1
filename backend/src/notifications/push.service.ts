import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as webPush from 'web-push';
import {
  PushSubscription,
  PushSubscriptionDocument,
} from './schemas/push-subscription.schema';

/** Status codes a push service returns for an endpoint that is gone. */
const GONE_STATUS_CODES = new Set([404, 410]);

export interface PushPayload {
  /** A notification id, so the page can deep-link on click. */
  notificationId: string;
  type: string;
  actorName?: string;
  actorRole: string;
}

/**
 * Delivery to the phone's own notification tray, via Web Push.
 *
 * **Optional infrastructure.** Without `VAPID_PUBLIC_KEY` /
 * `VAPID_PRIVATE_KEY` configured this service disables itself and every
 * method becomes a no-op. That is deliberate: push is an addition on top of
 * the in-app notification, which is the durable record. A development
 * machine, a test run, or a deploy where the keys were never set must all
 * keep working — just without banners.
 *
 * Nothing here throws at its caller. A push that failed to send is worth a
 * log line, never a failed invitation.
 */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private readonly enabled: boolean;

  constructor(
    @InjectModel(PushSubscription.name)
    private readonly subscriptionModel: Model<PushSubscription>,
    config: ConfigService,
  ) {
    const publicKey = config.get<string>('VAPID_PUBLIC_KEY');
    const privateKey = config.get<string>('VAPID_PRIVATE_KEY');
    // The VAPID "subject" identifies the sender to the push service and must
    // be a mailto: or https: URL. Falling back to the frontend URL keeps one
    // less thing to configure.
    const subject =
      config.get<string>('VAPID_SUBJECT') ??
      config.get<string>('FRONTEND_URL') ??
      'https://sportxhub.com';

    this.enabled = Boolean(publicKey && privateKey);
    if (this.enabled) {
      webPush.setVapidDetails(subject, publicKey!, privateKey!);
    } else {
      this.logger.warn(
        'Web Push disabled: VAPID_PUBLIC_KEY / VAPID_PRIVATE_KEY are not set. ' +
          'In-app notifications are unaffected.',
      );
    }
  }

  /** `null` when push is not configured — the client then skips its prompt. */
  publicKey(config: ConfigService): string | null {
    return this.enabled ? (config.get<string>('VAPID_PUBLIC_KEY') ?? null) : null;
  }

  get isEnabled(): boolean {
    return this.enabled;
  }

  /**
   * Register (or refresh) one browser.
   *
   * Upsert on `endpoint`, which is the subscription's identity: a browser
   * that re-subscribes — after a permission re-grant, or a key rotation —
   * must replace its row rather than add a second one, or every notification
   * would arrive twice. The upsert also re-points an endpoint at whoever is
   * signed in now, which is what makes a shared device behave.
   */
  async subscribe(input: {
    userId: Types.ObjectId | string;
    endpoint: string;
    p256dh: string;
    auth: string;
    userAgent?: string;
  }): Promise<void> {
    await this.subscriptionModel.updateOne(
      { endpoint: input.endpoint },
      {
        $set: {
          userId: input.userId,
          p256dh: input.p256dh,
          auth: input.auth,
          userAgent: input.userAgent,
        },
      },
      { upsert: true },
    );
  }

  /** Scoped to the caller, so nobody can unsubscribe another account. */
  async unsubscribe(userId: string, endpoint: string): Promise<void> {
    await this.subscriptionModel.deleteOne({ userId, endpoint });
  }

  /**
   * Send one notification to every browser [userId] has registered.
   *
   * Never throws. Endpoints that answer 404/410 are deleted — that is the
   * push service saying this browser is gone for good, and the only signal
   * there is. Any other failure is transient (a rate limit, an outage) and
   * the row is left alone.
   */
  async send(
    userId: Types.ObjectId | string,
    payload: PushPayload,
  ): Promise<void> {
    if (!this.enabled) return;

    let subscriptions: PushSubscriptionDocument[];
    try {
      subscriptions = await this.subscriptionModel.find({ userId });
    } catch {
      this.logger.error('Failed to read push subscriptions.');
      return;
    }
    if (subscriptions.length === 0) return;

    const body = JSON.stringify(payload);
    const dead: string[] = [];

    await Promise.all(
      subscriptions.map(async (subscription) => {
        try {
          await webPush.sendNotification(
            {
              endpoint: subscription.endpoint,
              keys: { p256dh: subscription.p256dh, auth: subscription.auth },
            },
            body,
          );
        } catch (error) {
          const statusCode = (error as { statusCode?: number }).statusCode;
          if (statusCode && GONE_STATUS_CODES.has(statusCode)) {
            dead.push(subscription.endpoint);
            return;
          }
          // Transient. Nothing to do about it, and nothing to clean up —
          // the in-app notification is already recorded either way.
          this.logger.warn(
            `Push send failed (status=${statusCode ?? 'unknown'}).`,
          );
        }
      }),
    );

    if (dead.length > 0) {
      await this.subscriptionModel
        .deleteMany({ endpoint: { $in: dead } })
        .catch(() => {
          this.logger.error('Failed to prune dead push subscriptions.');
        });
    }
  }
}
