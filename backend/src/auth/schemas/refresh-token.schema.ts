import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type RefreshTokenDocument = HydratedDocument<RefreshToken>;

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'refreshtokens',
})
export class RefreshToken {
  @Prop({ required: true, type: Types.ObjectId, ref: 'User', index: true })
  userId: Types.ObjectId;

  @Prop({ required: true, unique: true })
  tokenHash: string;

  @Prop({ required: true })
  expiresAt: Date;
}

export const RefreshTokenSchema = SchemaFactory.createForClass(RefreshToken);
// TTL index: MongoDB automatically deletes the document once expiresAt passes.
RefreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
