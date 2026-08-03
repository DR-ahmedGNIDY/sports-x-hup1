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

  @Prop({ default: false })
  isProfilePhoto: boolean;
}
export const PlayerMediaSchema = SchemaFactory.createForClass(PlayerMedia);

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

  @Prop()
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

  @Prop({ type: [AchievementSchema], default: [] })
  achievements: Achievement[];

  @Prop({ type: [SocialLinkSchema], default: [] })
  socialLinks: SocialLink[];
}

export const PlayerProfileSchema = SchemaFactory.createForClass(PlayerProfile);

// Compound index for the most common search combination (Phase 3). No
// standalone index on `sport` — it's already the compound's leading field,
// so a separate single-field index would be pure duplication. `country`
// and `position` are deliberately left without standalone indexes too:
// the roadmap only calls out visibility/preferredFoot/height/weight below.
PlayerProfileSchema.index({ sport: 1, position: 1, country: 1 });
