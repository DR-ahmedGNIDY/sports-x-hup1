import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum MembershipStatus {
  ACTIVE = 'ACTIVE',
  ENDED = 'ENDED',
}

export type ClubMembershipDocument = HydratedDocument<ClubMembership>;

// The official club↔player relationship, created only by accepting an
// invitation. Deliberately NOT the same thing as ClubManagedPlayer, which
// records that a club *created* a player's login (an irreversible provenance
// fact, and the authorization check every club-players endpoint relies on).
// A membership is a revocable affiliation: ending one leaves the account,
// the profile and the club-managed ownership row untouched.
@Schema({ timestamps: true, collection: 'club_memberships' })
export class ClubMembership {
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  clubUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  playerUserId: Types.ObjectId;

  @Prop({
    required: true,
    enum: MembershipStatus,
    default: MembershipStatus.ACTIVE,
  })
  status: MembershipStatus;

  // Which invitation produced this relationship — provenance, and the reason
  // a membership can always be traced back to a recorded consent.
  @Prop({ type: Types.ObjectId, required: true, ref: 'ClubPlayerInvitation' })
  invitationId: Types.ObjectId;

  @Prop({ required: true, default: () => new Date() })
  joinedAt: Date;

  @Prop()
  endedAt?: Date;
}

export const ClubMembershipSchema =
  SchemaFactory.createForClass(ClubMembership);

// "A player belongs to at most one club at a time", enforced by the database
// rather than by a check-then-insert. This is also what makes two clubs'
// invitations being accepted at the same instant safe without a transaction:
// exactly one insert wins, and the loser's accept is rolled back to PENDING.
// Partial on ACTIVE so a player's ENDED history is unbounded.
ClubMembershipSchema.index(
  { playerUserId: 1 },
  {
    unique: true,
    partialFilterExpression: { status: MembershipStatus.ACTIVE },
  },
);

// A club's roster page: filter by club + ACTIVE, newest first.
ClubMembershipSchema.index({ clubUserId: 1, status: 1, joinedAt: -1 });

// A player's club history (and the "does this player have a club?" check).
ClubMembershipSchema.index({ playerUserId: 1, status: 1 });
