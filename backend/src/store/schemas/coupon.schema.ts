import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export enum CouponType {
  /// A share of the subtotal — `value` is whole percent (10 = 10% off).
  PERCENT = 'percent',
  /// A flat amount off, in piastres like every other amount in the store.
  FIXED = 'fixed',
}

export type CouponDocument = HydratedDocument<Coupon>;

@Schema({ timestamps: true, collection: 'storecoupons' })
export class Coupon {
  /// What the customer types. Stored upper-cased and matched upper-cased,
  /// because a code is read off a post or a receipt and nobody types it in
  /// the case it was created in.
  @Prop({ required: true, unique: true, trim: true, uppercase: true })
  code: string;

  @Prop({ type: String, enum: CouponType, required: true })
  type: CouponType;

  /// Percent (1–100) or piastres, depending on [type]. One field rather
  /// than two nullable ones — a coupon is only ever one kind.
  @Prop({ required: true, min: 1 })
  value: number;

  /// The basket has to reach this before the code applies. Compared against
  /// the subtotal, never the total: otherwise a distant governorate's
  /// shipping fee could push an order over the threshold, and the same
  /// basket would qualify in Aswan but not in Cairo.
  @Prop({ default: 0, min: 0 })
  minSubtotalMinor: number;

  /// How many times it may be used in total. Null means unlimited — the
  /// common case for an open campaign code.
  @Prop({ min: 1 })
  maxRedemptions?: number;

  /// Incremented atomically as part of claiming the code, never recomputed
  /// by counting orders: counting would let two simultaneous checkouts both
  /// see the same "used" number and both pass the limit.
  @Prop({ default: 0, min: 0 })
  redemptions: number;

  @Prop()
  startsAt?: Date;

  @Prop()
  endsAt?: Date;

  /// The off switch, independent of the dates — a campaign can be stopped
  /// early without rewriting its schedule.
  @Prop({ default: true, index: true })
  isActive: boolean;
}

export const CouponSchema = SchemaFactory.createForClass(Coupon);
