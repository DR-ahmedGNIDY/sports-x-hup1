import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PhotoCommentDocument = HydratedDocument<PhotoComment>;

// Mirrors VideoComment exactly (see videos/schemas/video-comment.schema.ts).
@Schema({ timestamps: true, collection: 'photo_comments' })
export class PhotoComment {
  @Prop({ type: Types.ObjectId, required: true, index: true, ref: 'PhotoPost' })
  photoId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ required: true, trim: true, maxlength: 1000 })
  text: string;
}

export const PhotoCommentSchema = SchemaFactory.createForClass(PhotoComment);

PhotoCommentSchema.index({ photoId: 1, createdAt: 1 });
