import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type DeviceTokenDocument = HydratedDocument<DeviceToken>;

/**
 * One phone running the Android app, reachable through Firebase Cloud
 * Messaging. The native-app twin of PushSubscription: a token is unique per
 * install, so a phone that signs into another account re-points its row
 * rather than adding a second one.
 */
@Schema({ timestamps: true, collection: 'device_tokens' })
export class DeviceToken {
  // String, like every newer collection: Mongoose does not cast between a
  // string id and an ObjectId in queries, and callers pass strings.
  @Prop({ type: String, required: true })
  userId: string;

  @Prop({ required: true, unique: true })
  token: string;

  @Prop({ default: 'android' })
  platform: string;
}

export const DeviceTokenSchema = SchemaFactory.createForClass(DeviceToken);

DeviceTokenSchema.index({ userId: 1 });
