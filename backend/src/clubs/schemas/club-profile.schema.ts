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
}

export const ClubProfileSchema = SchemaFactory.createForClass(ClubProfile);
