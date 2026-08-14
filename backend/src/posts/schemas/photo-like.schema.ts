import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PhotoLikeDocument = HydratedDocument<PhotoLike>;

// Mirrors VideoLike exactly (see videos/schemas/video-like.schema.ts) —
// one row per (photo, user) pair, existence-checked for "did I like this".
@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'photo_likes',
})
export class PhotoLike {
  @Prop({ type: Types.ObjectId, required: true, index: true, ref: 'PhotoPost' })
  photoId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;
}

export const PhotoLikeSchema = SchemaFactory.createForClass(PhotoLike);

PhotoLikeSchema.index({ photoId: 1, userId: 1 }, { unique: true });
