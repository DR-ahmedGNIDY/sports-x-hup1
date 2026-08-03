import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PasswordResetTokenDocument = HydratedDocument<PasswordResetToken>;

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'passwordresettokens',
})
export class PasswordResetToken {
  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId: Types.ObjectId;

  @Prop({ required: true, unique: true })
  tokenHash: string;

  @Prop({ required: true })
  expiresAt: Date;
}

export const PasswordResetTokenSchema =
  SchemaFactory.createForClass(PasswordResetToken);
PasswordResetTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
