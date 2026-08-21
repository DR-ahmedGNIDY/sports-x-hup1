import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum VideoVisibility {
  PUBLIC = 'PUBLIC',
  PRIVATE = 'PRIVATE',
}

export type VideoDocument = HydratedDocument<Video>;

@Schema({ timestamps: true, collection: 'videos' })
export class Video {
  @Prop({
    type: Types.ObjectId,
    required: true,
    ref: 'PlayerProfile',
    index: true,
  })
  playerId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true, trim: true, index: true })
  sport: string;

  @Prop({ required: true, trim: true })
  category: string;

  @Prop({ trim: true, maxlength: 100 })
  title?: string;

  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;

  @Prop()
  thumbnailUrl?: string;

  @Prop({
    type: String,
    enum: VideoVisibility,
    required: true,
    default: VideoVisibility.PRIVATE,
    index: true,
  })
  visibility: VideoVisibility;

  @Prop({ default: 0 })
  likeCount: number;

  @Prop({ default: 0 })
  commentCount: number;
}

export const VideoSchema = SchemaFactory.createForClass(Video);

// Powers the Community feed query (public videos filtered by sport/category,
// newest first).
VideoSchema.index({ visibility: 1, sport: 1, category: 1, createdAt: -1 });
// Powers a player's own video list / public profile video list.
VideoSchema.index({ playerId: 1, createdAt: -1 });
