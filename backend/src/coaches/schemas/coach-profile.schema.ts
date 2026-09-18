import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import {
  Achievement,
  AchievementSchema,
  ContactDetails,
  ContactDetailsSchema,
  MediaType,
  ProfilePhoto,
  ProfilePhotoSchema,
  ProfileVisibility,
  SocialLink,
  SocialLinkSchema,
} from '../../players/schemas/player-profile.schema';

export type CoachProfileDocument = HydratedDocument<CoachProfile>;

@Schema({ _id: true, timestamps: false })
export class CoachMedia {
  _id?: Types.ObjectId;

  @Prop({ required: true, enum: MediaType })
  type: MediaType;

  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;

  @Prop({ trim: true, maxlength: 200 })
  caption?: string;
}
export const CoachMediaSchema = SchemaFactory.createForClass(CoachMedia);

// A coaching licence or course — "CAF C", "UEFA B", a goalkeeping course.
@Schema({ _id: true, timestamps: false })
export class Certification {
  _id?: Types.ObjectId;

  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ trim: true })
  issuer?: string;

  @Prop()
  year?: number;
}
export const CertificationSchema = SchemaFactory.createForClass(Certification);

// One line of the CV's career history. `endYear` absent means "to date".
@Schema({ _id: true, timestamps: false })
export class CoachExperience {
  _id?: Types.ObjectId;

  @Prop({ required: true, trim: true })
  clubName: string;

  @Prop({ required: true, trim: true })
  role: string;

  @Prop({ required: true })
  startYear: number;

  @Prop()
  endYear?: number;

  @Prop({ trim: true })
  description?: string;
}
export const CoachExperienceSchema =
  SchemaFactory.createForClass(CoachExperience);

// The coach's CV. Deliberately its own collection rather than a flavour of
// PlayerProfile: everything that reads playerprofiles (search, rosters,
// lineups, traits) assumes every row there is a player.
@Schema({ timestamps: true, collection: 'coachprofiles' })
export class CoachProfile {
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

  // The one-line title under the name — "Head coach", "Goalkeeping coach".
  @Prop({ trim: true })
  headline?: string;

  @Prop()
  yearsOfExperience?: number;

  @Prop({ trim: true })
  bio?: string;

  @Prop({ trim: true })
  education?: string;

  @Prop({ type: [String], default: [] })
  specialties: string[];

  @Prop({ type: [String], default: [] })
  preferredFormations: string[];

  @Prop({ type: [String], default: [] })
  languages: string[];

  @Prop({ type: ContactDetailsSchema, default: {} })
  contact: ContactDetails;

  // PUBLIC by default, unlike a player: a coach is recruited by code, and a
  // code only resolves for a public profile.
  @Prop({
    enum: ProfileVisibility,
    default: ProfileVisibility.PUBLIC,
    index: true,
  })
  visibility: ProfileVisibility;

  @Prop({ type: ProfilePhotoSchema })
  profilePhoto?: ProfilePhoto;

  @Prop({ type: [CoachMediaSchema], default: [] })
  media: CoachMedia[];

  @Prop({ type: [CertificationSchema], default: [] })
  certifications: Certification[];

  @Prop({ type: [CoachExperienceSchema], default: [] })
  experience: CoachExperience[];

  @Prop({ type: [AchievementSchema], default: [] })
  achievements: Achievement[];

  @Prop({ type: [SocialLinkSchema], default: [] })
  socialLinks: SocialLink[];

  // "COA-000123" — same contract as PlayerProfile.publicCode.
  @Prop({ unique: true, sparse: true, trim: true })
  publicCode?: string;
}

export const CoachProfileSchema = SchemaFactory.createForClass(CoachProfile);

CoachProfileSchema.index({ visibility: 1, sport: 1, country: 1 });
