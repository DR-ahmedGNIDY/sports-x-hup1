import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum NotificationType {
  INVITATION_RECEIVED = 'INVITATION_RECEIVED',
  INVITATION_ACCEPTED = 'INVITATION_ACCEPTED',
  INVITATION_REJECTED = 'INVITATION_REJECTED',
  EVENT_SCHEDULED = 'EVENT_SCHEDULED',
  // Sent to every admin when the storefront takes an order.
  ORDER_PLACED = 'ORDER_PLACED',
  // A player's academy subscription, told to both the club and the player.
  SUBSCRIPTION_EXPIRING = 'SUBSCRIPTION_EXPIRING',
  SUBSCRIPTION_EXPIRED = 'SUBSCRIPTION_EXPIRED',
  // The club asking a player to renew. Repeatable — see emitFresh.
  SUBSCRIPTION_REMINDER = 'SUBSCRIPTION_REMINDER',
}

// One value today. It exists so the dedupe index and the client's "what do I
// open when this is tapped" switch are both keyed on something that can grow
// without a migration.
export enum NotificationEntityType {
  INVITATION = 'INVITATION',
  // A club↔coach invitation — its own collection, so its own entity type:
  // the client opens the coach-invitations screen for it, not the player one.
  COACH_INVITATION = 'COACH_INVITATION',
  CALENDAR_EVENT = 'CALENDAR_EVENT',
  STORE_ORDER = 'STORE_ORDER',
  PLAYER_SUBSCRIPTION = 'PLAYER_SUBSCRIPTION',
}

/** Whose name a notification names. */
export enum NotificationActorRole {
  CLUB = 'CLUB',
  PLAYER = 'PLAYER',
  COACH = 'COACH',
  /** The buyer behind a store order — often a guest with no profile. */
  CUSTOMER = 'CUSTOMER',
}

export type NotificationDocument = HydratedDocument<Notification>;

// The structured payload. Deliberately small, and deliberately free of
// contact details: a notification must never become a way to read a phone
// number that GET /players/:id/contact guards.
export interface NotificationParams {
  /** The other party — who did the thing being announced. */
  actorName?: string;
  actorRole: NotificationActorRole;
  /** Their *profile* id, so the client can link to a public profile. */
  actorProfileId?: string;
  actorPublicCode?: string;

  // Calendar events only. A player is told *which* session they were added
  // to and when, rather than having to open the event to find out.
  eventName?: string;
  /** MATCH | TRAINING | OTHER, so the client can name the kind of session. */
  eventType?: string;
  /** 'YYYY-MM-DD'. */
  eventDate?: string;
  /** 'HH:mm'. */
  eventStartTime?: string;

  // Store orders only. The number and total are what an admin needs to
  // decide whether to open it now; the buyer's phone and address stay on
  // the order, behind the admin endpoints.
  orderNumber?: string;
  orderTotalMinor?: number;

  // Subscriptions only. 'YYYY-MM-DD', and the player the subscription is
  // for, so the club's tap can open that player's reminder options.
  subscriptionEndDate?: string;
  subscriptionPlayerUserId?: string;
}

@Schema({ timestamps: true, collection: 'notifications' })
export class Notification {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true, enum: NotificationType })
  type: NotificationType;

  // Structured, never rendered text.
  //
  // This app is bilingual and Arabic is the default. A row storing
  // "نادي الأهلي دعاك للانضمام" would still be Arabic after the reader
  // switches to English, and a later copy-edit would never reach anything
  // already stored. Keeping the pieces here and rendering on the client from
  // the same .arb files as the rest of the app means neither happens.
  @Prop({ type: Object, required: true, default: {} })
  params: NotificationParams;

  @Prop({ required: true, enum: NotificationEntityType })
  entityType: NotificationEntityType;

  // What to open on tap.
  @Prop({ type: Types.ObjectId, required: true })
  entityId: Types.ObjectId;

  // Absent means unread. A nullable date rather than a boolean because
  // "when did they see it" is worth having and costs the same.
  @Prop()
  readAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

// The list: one user's notifications, newest first.
NotificationSchema.index({ userId: 1, createdAt: -1 });

// The badge count. `readAt` is sparse in practice (most rows are unread),
// but the index is on the pair so the count never scans the user's history.
NotificationSchema.index({ userId: 1, readAt: 1 });

// The dedupe rule, enforced by the database rather than by a read-then-write.
// One notification per recipient per entity per type: a club that sends,
// withdraws and re-sends produces one unread row, not three. The service
// swallows the resulting duplicate-key error — a duplicate is a success.
NotificationSchema.index(
  { userId: 1, entityType: 1, entityId: 1, type: 1 },
  { unique: true },
);
