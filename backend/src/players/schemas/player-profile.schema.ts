import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum PreferredFoot {
  LEFT = 'LEFT',
  RIGHT = 'RIGHT',
  BOTH = 'BOTH',
}

export enum ProfileVisibility {
  PUBLIC = 'PUBLIC',
  PRIVATE = 'PRIVATE',
}

export enum MediaType {
  PHOTO = 'PHOTO',
  VIDEO = 'VIDEO',
}

export type PlayerProfileDocument = HydratedDocument<PlayerProfile>;

@Schema({ _id: true, timestamps: false })
export class ContactDetails {
  @Prop({ trim: true })
  phone?: string;

  @Prop({ trim: true, lowercase: true })
  email?: string;

  @Prop({ trim: true })
  whatsapp?: string;
}
export const ContactDetailsSchema =
  SchemaFactory.createForClass(ContactDetails);

@Schema({ _id: true, timestamps: false })
export class PlayerMedia {
  _id?: Types.ObjectId;

  @Prop({ required: true, enum: MediaType })
  type: MediaType;

  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;

  // Legacy — no longer set by any code path (the profile photo now lives
  // in its own `profilePhoto` field below, outside this album array). Kept
  // on the schema only so old documents (pre-migration) still deserialize;
  // see database/migrate-profile-photos.ts.
  @Prop({ default: false })
  isProfilePhoto: boolean;
}
export const PlayerMediaSchema = SchemaFactory.createForClass(PlayerMedia);

@Schema({ _id: false, timestamps: false })
export class ProfilePhoto {
  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;
}
export const ProfilePhotoSchema = SchemaFactory.createForClass(ProfilePhoto);

@Schema({ _id: true, timestamps: false })
export class Achievement {
  _id?: Types.ObjectId;

  @Prop({ required: true, trim: true })
  title: string;

  @Prop({ required: true })
  year: number;

  @Prop({ trim: true })
  description?: string;
}
export const AchievementSchema = SchemaFactory.createForClass(Achievement);

@Schema({ _id: true, timestamps: false })
export class SocialLink {
  _id?: Types.ObjectId;

  @Prop({ required: true, trim: true })
  platform: string;

  @Prop({ required: true, trim: true })
  url: string;
}
export const SocialLinkSchema = SchemaFactory.createForClass(SocialLink);

@Schema({ timestamps: true, collection: 'playerprofiles' })
export class PlayerProfile {
  @Prop({ type: Types.ObjectId, required: true, unique: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ trim: true })
  firstName?: string;

  @Prop({ trim: true })
  lastName?: string;

  // Indexed: Age (minAge/maxAge) is one of Phase 3's 7 search filters,
  // resolved as a range query against this field, and it isn't covered
  // by the compound index below — without this, an age-only search would
  // force a full collection scan.
  @Prop({ index: true })
  dateOfBirth?: Date;

  @Prop({ trim: true })
  nationality?: string;

  @Prop({ trim: true })
  country?: string;

  @Prop({ trim: true })
  city?: string;

  @Prop({ trim: true })
  sport?: string;

  @Prop({ trim: true })
  position?: string;

  @Prop({ enum: PreferredFoot, index: true })
  preferredFoot?: PreferredFoot;

  @Prop({ index: true })
  height?: number;

  @Prop({ index: true })
  weight?: number;

  @Prop({ trim: true })
  currentStatus?: string;

  @Prop({ trim: true })
  currentClub?: string;

  @Prop({ trim: true })
  bio?: string;

  @Prop({ type: ContactDetailsSchema, default: {} })
  contact: ContactDetails;

  @Prop({
    enum: ProfileVisibility,
    default: ProfileVisibility.PRIVATE,
    index: true,
  })
  visibility: ProfileVisibility;

  @Prop({ type: [PlayerMediaSchema], default: [] })
  media: PlayerMedia[];

  // Separate from `media` on purpose — uploading a profile photo must not
  // count toward the album (MAX_EMBEDDED_ARRAY_ITEMS) or show up in the
  // gallery grid.
  @Prop({ type: ProfilePhotoSchema })
  profilePhoto?: ProfilePhoto;

  @Prop({ type: [AchievementSchema], default: [] })
  achievements: Achievement[];

  @Prop({ type: [SocialLinkSchema], default: [] })
  socialLinks: SocialLink[];

  // Public, shareable identity (e.g. "PLY-000123") — see the matching field
  // on ClubProfile. Assigned once by `PlayersService.ensurePublicCode`,
  // never rewritten; `sparse` so profiles awaiting backfill don't collide
  // on null.
  @Prop({ unique: true, sparse: true, trim: true })
  publicCode?: string;
}

export const PlayerProfileSchema = SchemaFactory.createForClass(PlayerProfile);

// Compound index for the most common search combination (Phase 3). No
// standalone index on `sport` — it's already the compound's leading field,
// so a separate single-field index would be pure duplication. `country`
// and `position` are deliberately left without standalone indexes too:
// the roadmap only calls out visibility/preferredFoot/height/weight below.
PlayerProfileSchema.index({ sport: 1, position: 1, country: 1 });
