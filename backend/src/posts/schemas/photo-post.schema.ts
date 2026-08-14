import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PhotoPostDocument = HydratedDocument<PhotoPost>;

// The author can be either a Player or a Club — unlike Video (player-only),
// a photo Post is meant to cover "club posted a training-camp photo" too
// (see the Home feed spec). `authorRole` decides how the mapper resolves
// the author summary (PlayerProfile vs ClubProfile) without an extra query
// to re-derive it from the User collection on every feed read.
export enum PostAuthorRole {
  PLAYER = 'PLAYER',
  CLUB = 'CLUB',
}

@Schema({ timestamps: true, collection: 'photo_posts' })
export class PhotoPost {
  @Prop({ type: Types.ObjectId, required: true, index: true, ref: 'User' })
  authorUserId: Types.ObjectId;

  @Prop({ required: true, enum: PostAuthorRole })
  authorRole: PostAuthorRole;

  // Always required, same role it plays for Video: scopes the item to a
  // sport so the Home feed can stay sport-scoped without a join. A Player
  // gets it from their own profile at post time; a Club (no `sport` field
  // on ClubProfile) picks it explicitly — see CreatePhotoPostDto.
  @Prop({ required: true, trim: true, index: true })
  sport: string;

  @Prop({ trim: true, maxlength: 500 })
  caption?: string;

  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;

  @Prop({ default: 0 })
  likeCount: number;

  @Prop({ default: 0 })
  commentCount: number;
}

export const PhotoPostSchema = SchemaFactory.createForClass(PhotoPost);

// Powers the Home feed query (public photos filtered by sport, newest
// first) — mirrors Video's community-feed index.
PhotoPostSchema.index({ sport: 1, createdAt: -1 });
// Powers "my posts" / cascade-delete lookups.
PhotoPostSchema.index({ authorUserId: 1, createdAt: -1 });
