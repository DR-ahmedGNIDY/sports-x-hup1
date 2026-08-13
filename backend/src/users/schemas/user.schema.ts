import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export enum UserRole {
  PLAYER = 'PLAYER',
  CLUB = 'CLUB',
  ADMIN = 'ADMIN',
}

export enum UserStatus {
  ACTIVE = 'ACTIVE',
  SUSPENDED = 'SUSPENDED',
}

export type UserDocument = HydratedDocument<User>;

@Schema({ timestamps: true, collection: 'users' })
export class User {
  // Optional: self-registered users always have one (enforced by
  // RegisterDto), but a club-created player account may only have a phone.
  @Prop({ required: false, unique: true, sparse: true, lowercase: true, trim: true })
  email?: string;

  // Optional: only set for club-created player accounts, which log in with
  // this as their username instead of an email. Stored as dial code + local
  // digits (e.g. "+201234567890"), no separators.
  @Prop({ required: false, unique: true, sparse: true, trim: true })
  phone?: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true, enum: UserRole })
  role: UserRole;

  @Prop({ required: true, enum: UserStatus, default: UserStatus.ACTIVE })
  status: UserStatus;
}

export const UserSchema = SchemaFactory.createForClass(User);
