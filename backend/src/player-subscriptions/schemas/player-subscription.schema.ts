import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum SubscriptionPlan {
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
  CUSTOM = 'CUSTOM',
}

export type PlayerSubscriptionDocument = HydratedDocument<PlayerSubscription>;

// One paid period of a player's training at a club's academy. A renewal is
// a new row, not an edit, so the history doubles as a payment record.
//
// Dates are 'YYYY-MM-DD' strings in the club's local calendar (Cairo), not
// Date instants: "ends on the 30th" means the whole of the 30th wherever the
// server happens to run, and the strings sort and compare correctly as-is.
@Schema({ timestamps: true, collection: 'player_subscriptions' })
export class PlayerSubscription {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  clubUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  playerUserId: Types.ObjectId;

  @Prop({ required: true, enum: SubscriptionPlan })
  plan: SubscriptionPlan;

  @Prop({ required: true })
  startDate: string;

  @Prop({ required: true })
  endDate: string;

  // Piastres, like the store. What was agreed, and how much of it is in.
  @Prop({ required: true, min: 0, default: 0 })
  amountMinor: number;

  @Prop({ required: true, min: 0, default: 0 })
  paidMinor: number;

  @Prop({ trim: true, maxlength: 500 })
  notes?: string;

  // Set by the daily job once each announcement has gone out, so a restart
  // or a second run on the same day never sends it twice.
  @Prop()
  expiringNotifiedAt?: Date;

  @Prop()
  expiredNotifiedAt?: Date;

  // The club's manual "please renew" — limited to one a day.
  @Prop()
  lastReminderAt?: Date;
}

export const PlayerSubscriptionSchema =
  SchemaFactory.createForClass(PlayerSubscription);

// A player's history at one club, newest period first — also how "the
// current subscription" is found.
PlayerSubscriptionSchema.index({ clubUserId: 1, playerUserId: 1, endDate: -1 });

// The daily job: subscriptions ending in a date window.
PlayerSubscriptionSchema.index({ endDate: 1 });

// A player's own view, across clubs.
PlayerSubscriptionSchema.index({ playerUserId: 1, endDate: -1 });
