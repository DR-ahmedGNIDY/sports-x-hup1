import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PushSubscriptionDocument = HydratedDocument<PushSubscription>;

/**
 * One browser's permission to be pushed to.
 *
 * A user has several: a phone, a laptop, a second browser. They are not
 * credentials the user manages — they are issued by the browser's own push
 * service and can die at any moment (permission revoked, app uninstalled,
 * profile cleared), silently and without telling anyone. Pruning on a
 * 404/410 from the push service is therefore part of the design, not
 * housekeeping: without it the collection grows forever and every send
 * spends requests on endpoints that will never deliver again.
 */
@Schema({ timestamps: true, collection: 'push_subscriptions' })
export class PushSubscription {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;

  // The push service's URL for this browser. Unique because it *is* the
  // identity of a subscription — re-subscribing the same browser must
  // update the existing row rather than add a second one that would make
  // every notification arrive twice.
  @Prop({ required: true, unique: true })
  endpoint: string;

  // The browser's public key and auth secret, used to encrypt the payload
  // so the push service relays something it cannot read.
  @Prop({ required: true })
  p256dh: string;

  @Prop({ required: true })
  auth: string;

  // Only to help a user recognise a device in a future "your sessions"
  // screen. Never parsed for behaviour.
  @Prop()
  userAgent?: string;
}

export const PushSubscriptionSchema =
  SchemaFactory.createForClass(PushSubscription);

// Every send starts here: all of one user's browsers.
PushSubscriptionSchema.index({ userId: 1 });
