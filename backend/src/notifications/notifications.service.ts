import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { PushService } from './push.service';
import {
  Notification,
  NotificationDocument,
  NotificationEntityType,
  NotificationParams,
  NotificationType,
} from './schemas/notification.schema';

const NOTIFICATIONS_PAGE_SIZE = 20;
const DUPLICATE_KEY_ERROR_CODE = 11000;

export interface NotificationPage {
  items: NotificationDocument[];
  page: number;
  pageSize: number;
  total: number;
}

export interface EmitInput {
  userId: Types.ObjectId | string;
  type: NotificationType;
  entityType: NotificationEntityType;
  entityId: Types.ObjectId | string;
  params: NotificationParams;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<Notification>,
    private readonly push: PushService,
  ) {}

  /**
   * Record a notification. **Never throws.**
   *
   * Callers invoke this after their own state transition has already
   * committed, so a failure here must not turn a successful accept into an
   * error the user sees. The invitation is the fact; this is an announcement
   * of it, and an announcement that did not go out is worth a log line, not
   * a rolled-back relationship.
   *
   * A duplicate is a success: the unique index on
   * `{ userId, entityType, entityId, type }` is the dedupe rule, so a repeat
   * emission for the same event returns the row that already exists rather
   * than adding a second unread item.
   */
  async emit(input: EmitInput): Promise<NotificationDocument | null> {
    try {
      const created = await this.notificationModel.create({
        userId: input.userId,
        type: input.type,
        entityType: input.entityType,
        entityId: input.entityId,
        params: input.params,
      });

      // Push rides on the *creation* branch only, so the dedupe index
      // silences the banner as well as the row: send, withdraw, re-send
      // buzzes a phone once. Not awaited — a slow push service must not
      // hold the request that caused it open, and the notification is
      // already durable by this line.
      void this.push.send(input.userId, {
        notificationId: created._id.toString(),
        type: input.type,
        actorName: input.params.actorName,
        actorRole: input.params.actorRole,
      });

      return created;
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        return this.notificationModel.findOne({
          userId: input.userId,
          entityType: input.entityType,
          entityId: input.entityId,
          type: input.type,
        });
      }
      // Deliberately swallowed. See the doc comment above.
      this.logger.error(
        `Failed to record notification (type=${input.type}, entityId=${String(
          input.entityId,
        )}).`,
      );
      return null;
    }
  }

  // `userId` is part of the query, not a check performed after fetching, so
  // no caller can read another account's notifications — the same rule the
  // invitations feature already follows.
  async list(
    userId: string,
    { page = 1, unreadOnly = false }: { page?: number; unreadOnly?: boolean },
  ): Promise<NotificationPage> {
    const filter: Record<string, unknown> = { userId };
    if (unreadOnly) filter.readAt = { $exists: false };

    const [items, total] = await Promise.all([
      this.notificationModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * NOTIFICATIONS_PAGE_SIZE)
        .limit(NOTIFICATIONS_PAGE_SIZE),
      this.notificationModel.countDocuments(filter),
    ]);

    return { items, page, pageSize: NOTIFICATIONS_PAGE_SIZE, total };
  }

  /** The badge. Cheap enough to poll; one indexed count, no documents. */
  async unreadCount(userId: string): Promise<number> {
    return this.notificationModel.countDocuments({
      userId,
      readAt: { $exists: false },
    });
  }

  // Guarded on `readAt` being absent so re-reading an already-read
  // notification is a no-op rather than rewriting when it was first seen.
  async markRead(userId: string, id: string): Promise<NotificationDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Notification not found.');
    }
    const updated = await this.notificationModel.findOneAndUpdate(
      { _id: id, userId, readAt: { $exists: false } },
      { $set: { readAt: new Date() } },
      { new: true },
    );
    if (updated) return updated;

    // Either it is already read, or it is not this caller's. The two answer
    // differently on purpose: the first is a success (the caller's intent is
    // satisfied), the second is a 404 that does not disclose existence.
    const existing = await this.notificationModel.findOne({ _id: id, userId });
    if (!existing) throw new NotFoundException('Notification not found.');
    return existing;
  }

  /** One write, not N. Returns how many were still unread. */
  async markAllRead(userId: string): Promise<number> {
    const result = await this.notificationModel.updateMany(
      { userId, readAt: { $exists: false } },
      { $set: { readAt: new Date() } },
    );
    return result.modifiedCount;
  }
}
