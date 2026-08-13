import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type VideoCommentDocument = HydratedDocument<VideoComment>;

@Schema({ timestamps: true, collection: 'videocomments' })
export class VideoComment {
  @Prop({ type: Types.ObjectId, required: true, ref: 'Video', index: true })
  videoId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true, trim: true, maxlength: 1000 })
  text: string;
}

export const VideoCommentSchema = SchemaFactory.createForClass(VideoComment);

VideoCommentSchema.index({ videoId: 1, createdAt: 1 });
