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
  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true, enum: UserRole })
  role: UserRole;

  @Prop({ required: true, enum: UserStatus, default: UserStatus.ACTIVE })
  status: UserStatus;
}

export const UserSchema = SchemaFactory.createForClass(User);
