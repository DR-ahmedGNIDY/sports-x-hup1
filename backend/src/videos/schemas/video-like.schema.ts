import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type VideoLikeDocument = HydratedDocument<VideoLike>;

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'videolikes',
})
export class VideoLike {
  @Prop({ type: Types.ObjectId, required: true, ref: 'Video', index: true })
  videoId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;
}

export const VideoLikeSchema = SchemaFactory.createForClass(VideoLike);

// Prevents the same user liking the same video twice at the database level.
VideoLikeSchema.index({ videoId: 1, userId: 1 }, { unique: true });
