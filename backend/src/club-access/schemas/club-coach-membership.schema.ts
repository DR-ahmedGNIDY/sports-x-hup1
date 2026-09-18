import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { MembershipStatus } from '../../invitations/schemas/club-membership.schema';
import {
  CoachPermission,
  DEFAULT_COACH_PERMISSIONS,
} from '../coach-permission.enum';

export type ClubCoachMembershipDocument = HydratedDocument<ClubCoachMembership>;

// A coach on a club's staff. Kept apart from ClubMembership (players) on
// purpose: rosters, lineups and squad counts all read that collection and
// assume every row is a player.
//
// Unlike a player, a coach may be on several clubs' staff at once — the
// uniqueness rule is per (club, coach) pair, not per coach.
@Schema({ timestamps: true, collection: 'club_coach_memberships' })
export class ClubCoachMembership {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  clubUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  coachUserId: Types.ObjectId;

  @Prop({
    required: true,
    enum: MembershipStatus,
    default: MembershipStatus.ACTIVE,
  })
  status: MembershipStatus;

  @Prop({ type: Types.ObjectId, required: true, ref: 'ClubCoachInvitation' })
  invitationId: Types.ObjectId;

  @Prop({
    type: [String],
    enum: CoachPermission,
    default: () => [...DEFAULT_COACH_PERMISSIONS],
  })
  permissions: CoachPermission[];

  @Prop({ required: true, default: () => new Date() })
  joinedAt: Date;

  @Prop()
  endedAt?: Date;
}

export const ClubCoachMembershipSchema =
  SchemaFactory.createForClass(ClubCoachMembership);

// One live membership per pair — a coach can't be on the same staff twice,
// and two simultaneous accepts can't both land. Partial on ACTIVE so the
// history of a coach who left and came back is kept.
ClubCoachMembershipSchema.index(
  { clubUserId: 1, coachUserId: 1 },
  {
    unique: true,
    partialFilterExpression: { status: MembershipStatus.ACTIVE },
  },
);

// A club's staff list.
ClubCoachMembershipSchema.index({ clubUserId: 1, status: 1, joinedAt: -1 });

// A coach's clubs.
ClubCoachMembershipSchema.index({ coachUserId: 1, status: 1 });
