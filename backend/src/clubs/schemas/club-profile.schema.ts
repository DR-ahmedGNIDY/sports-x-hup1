import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ClubProfileDocument = HydratedDocument<ClubProfile>;

@Schema({ _id: false, timestamps: false })
export class ClubLogo {
  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;
}
export const ClubLogoSchema = SchemaFactory.createForClass(ClubLogo);

@Schema({ timestamps: true, collection: 'clubprofiles' })
export class ClubProfile {
  @Prop({ type: Types.ObjectId, required: true, unique: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ trim: true })
  name?: string;

  @Prop({ trim: true, index: true })
  country?: string;

  @Prop({ trim: true, index: true })
  city?: string;

  @Prop({ type: ClubLogoSchema })
  logo?: ClubLogo;

  @Prop({ trim: true })
  description?: string;

  @Prop()
  foundedYear?: number;

  @Prop({ trim: true })
  level?: string;

  // Public, shareable identity (e.g. "CLB-000123") — safe to print on a
  // profile and to search by, and it never exposes the Mongo _id. Optional
  // on the schema only because profiles created before this feature existed
  // have none until `ClubsService.ensurePublicCode` (or the backfill script)
  // assigns one; it is assigned exactly once and never rewritten. `sparse`
  // so those not-yet-backfilled documents don't all collide on null.
  @Prop({ unique: true, sparse: true, trim: true })
  publicCode?: string;
}

export const ClubProfileSchema = SchemaFactory.createForClass(ClubProfile);
