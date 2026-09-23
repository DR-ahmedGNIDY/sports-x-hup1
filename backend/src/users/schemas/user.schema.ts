import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export enum UserRole {
  PLAYER = 'PLAYER',
  CLUB = 'CLUB',
  COACH = 'COACH',
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
  @Prop({
    required: false,
    unique: true,
    sparse: true,
    lowercase: true,
    trim: true,
  })
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

  // When a SUSPENDED user becomes eligible to log in again. Absent means
  // the suspension is permanent — there is no date to wait for. It is only
  // meaningful while `status` is SUSPENDED; reactivating clears it.
  //
  // The lift is lazy: rather than a scheduled job sweeping the collection,
  // both login (AuthService) and every authenticated request (JwtStrategy)
  // route the user through `UsersService.liftExpiredSuspension` first, so
  // an expired suspension ends the moment the account is next used.
  @Prop({ type: Date, required: false })
  suspendedUntil?: Date;

  // Admin-written note explaining the suspension. Shown back to the admin
  // in the dashboard, never to the suspended user.
  @Prop({ required: false, trim: true })
  suspensionReason?: string;

  // Community moderation: lets a non-admin user hide or delete other
  // people's Home-feed posts. Orthogonal to `role` on purpose — a player,
  // a club or a coach can each be made a moderator without becoming an
  // ADMIN (which would also unlock the whole admin dashboard).
  @Prop({ required: true, default: false })
  isModerator: boolean;
}

export const UserSchema = SchemaFactory.createForClass(User);
