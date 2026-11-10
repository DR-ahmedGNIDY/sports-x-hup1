import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { readFileSync } from 'fs';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { Model } from 'mongoose';
import { DeviceToken } from './schemas/device-token.schema';
import type { PushPayload } from './push.service';

/** FCM errors that mean the token will never deliver again. */
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/**
 * Banner text for the Android app. Unlike Web Push, where the service
 * worker renders the text, an FCM "notification" message is drawn by
 * Android itself while the app is closed — so the server writes it. Arabic,
 * the app's default language. Mirrors `pushBody` / `pushPath` in
 * frontend/web/sxh_service_worker.js; keep the two in step.
 */
export function fcmText(data: PushPayload): { body: string; path: string } {
  const actor = data.actorName?.trim();
  const isClub = data.actorRole === 'CLUB';
  const who = actor || (isClub ? 'نادٍ' : 'لاعب');
  const date = (data.subscriptionEndDate ?? '').replace(/-/g, '/');

  switch (data.type) {
    case 'ORDER_PLACED': {
      const total =
        typeof data.orderTotalMinor === 'number'
          ? (data.orderTotalMinor / 100).toFixed(2)
          : '—';
      return {
        body: `طلب جديد ${data.orderNumber ?? ''} من ${actor || 'عميل'} — ${total} ج.م`,
        path: '/admin/store',
      };
    }
    case 'TOURNAMENT_SCHEDULED':
    case 'TOURNAMENT_RESULT': {
      const path = data.tournamentId
        ? `/player/tournaments/${data.tournamentId}`
        : '/player/tournaments';
      const name = data.tournamentName ?? '';
      return {
        body:
          data.type === 'TOURNAMENT_SCHEDULED'
            ? `${actor || 'نادٍ'} نشر جدول ${name}.`
            : `اتسجّلت نتيجة مباراتك في ${name}.`,
        path,
      };
    }
    case 'SUBSCRIPTION_EXPIRING':
    case 'SUBSCRIPTION_EXPIRED':
    case 'SUBSCRIPTION_REMINDER': {
      // The player's copy names the club (the actor is the club); the
      // club's copy names the player.
      const path = isClub
        ? '/player/subscription'
        : data.subscriptionPlayerUserId
          ? `/club/subscriptions/${data.subscriptionPlayerUserId}`
          : '/club/subscriptions';
      if (data.type === 'SUBSCRIPTION_REMINDER') {
        return { body: `${who} بيفكّرك تجدّد اشتراكك.`, path };
      }
      const verb = data.type === 'SUBSCRIPTION_EXPIRED' ? 'انتهى' : 'هينتهي';
      const body = isClub
        ? `اشتراكك في ${who} ${verb} يوم ${date}.`
        : `اشتراك ${who} ${verb} يوم ${date}.`;
      return { body, path };
    }
    case 'INVITATION_RECEIVED':
      return {
        body: isClub
          ? `${who} دعاك للانضمام إلى النادي.`
          : `${who} طلب الانضمام إلى ناديك.`,
        path: '/notifications',
      };
    case 'INVITATION_ACCEPTED':
      return { body: `${who} قَبِل دعوتك.`, path: '/notifications' };
    case 'INVITATION_REJECTED':
      return { body: `${who} رفض دعوتك.`, path: '/notifications' };
    case 'EVENT_SCHEDULED': {
      const kind =
        data.eventType === 'MATCH'
          ? 'مباراة'
          : data.eventType === 'TRAINING'
            ? 'تدريب'
            : 'نشاط';
      const name = data.eventName?.trim();
      return {
        body: `${who} سجّلك في ${name ? `${kind} — ${name}` : kind}.`,
        path: '/notifications',
      };
    }
    default:
      return { body: 'لديك إشعار جديد.', path: '/notifications' };
  }
}

/**
 * Push to the Android app via Firebase Cloud Messaging.
 *
 * Optional, like Web Push: without `FIREBASE_SERVICE_ACCOUNT_PATH` (a path
 * to the service-account JSON from the Firebase console) it disables
 * itself and every send is a no-op. Never throws at its caller.
 */
@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private readonly app: App | null;

  constructor(
    @InjectModel(DeviceToken.name)
    private readonly tokenModel: Model<DeviceToken>,
    config: ConfigService,
  ) {
    this.app = FcmService.boot(
      config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH'),
    );
    if (!this.app) {
      this.logger.warn(
        'FCM disabled: FIREBASE_SERVICE_ACCOUNT_PATH is not set or unreadable. ' +
          'Android app push is off; everything else is unaffected.',
      );
    }
  }

  private static boot(path?: string): App | null {
    if (!path) return null;
    try {
      const existing = getApps()[0];
      if (existing) return existing;
      const account = JSON.parse(readFileSync(path, 'utf8'));
      return initializeApp({ credential: cert(account) });
    } catch {
      return null;
    }
  }

  async register(userId: string, token: string, platform = 'android') {
    await this.tokenModel.updateOne(
      { token },
      { $set: { userId, platform } },
      { upsert: true },
    );
  }

  /** Scoped to the caller, so nobody can silence someone else's phone. */
  async unregister(userId: string, token: string) {
    await this.tokenModel.deleteOne({ userId, token });
  }

  async unregisterAll(userId: string) {
    await this.tokenModel.deleteMany({ userId });
  }

  async send(userId: string, payload: PushPayload): Promise<void> {
    if (!this.app) return;
    try {
      const rows = await this.tokenModel.find({ userId }).lean();
      if (rows.length === 0) return;
      const tokens = rows.map((r) => r.token);
      const { body, path } = fcmText(payload);

      const result = await getMessaging(this.app).sendEachForMulticast({
        tokens,
        notification: { title: 'Sport X Hub', body },
        data: {
          path,
          notificationId: payload.notificationId,
          type: payload.type,
        },
        android: {
          priority: 'high',
          notification: { tag: payload.notificationId, defaultSound: true },
        },
      });

      const dead = result.responses
        .map((r, i) =>
          !r.success && DEAD_TOKEN_CODES.has(r.error?.code ?? '')
            ? tokens[i]
            : null,
        )
        .filter((t): t is string => t !== null);
      if (dead.length > 0) {
        await this.tokenModel.deleteMany({ token: { $in: dead } });
      }
    } catch (error) {
      this.logger.warn(`FCM send failed: ${(error as Error).message}`);
    }
  }
}
