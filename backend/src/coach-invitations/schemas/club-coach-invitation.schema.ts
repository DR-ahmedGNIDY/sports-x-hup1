import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import {
  defaultExpiresAt,
  INVITATION_MESSAGE_MAX_LENGTH,
  InvitationStatus,
} from '../../invitations/schemas/club-player-invitation.schema';

export enum CoachInvitationType {
  CLUB_TO_COACH = 'CLUB_TO_COACH',
  COACH_TO_CLUB = 'COACH_TO_CLUB',
}

export type ClubCoachInvitationDocument = HydratedDocument<ClubCoachInvitation>;

// The club↔coach counterpart of ClubPlayerInvitation — same state machine
// (PENDING → ACCEPTED | REJECTED | CANCELLED | EXPIRED), same expiry, same
// one-live-invitation-per-pair rule. Accepting creates a ClubCoachMembership.
@Schema({ timestamps: true, collection: 'club_coach_invitations' })
export class ClubCoachInvitation {
  @Prop({ required: true, enum: CoachInvitationType })
  type: CoachInvitationType;

  @Prop({
    required: true,
    enum: InvitationStatus,
    default: InvitationStatus.PENDING,
  })
  status: InvitationStatus;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  clubUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  coachUserId: Types.ObjectId;

  // Derived from `type` by the service, never taken from a request.
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  senderUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  recipientUserId: Types.ObjectId;

  @Prop({ trim: true, maxlength: INVITATION_MESSAGE_MAX_LENGTH })
  message?: string;

  @Prop({ required: true, default: defaultExpiresAt })
  expiresAt: Date;

  @Prop()
  respondedAt?: Date;
}

export const ClubCoachInvitationSchema =
  SchemaFactory.createForClass(ClubCoachInvitation);

ClubCoachInvitationSchema.index({
  recipientUserId: 1,
  status: 1,
  createdAt: -1,
});
ClubCoachInvitationSchema.index({ senderUserId: 1, status: 1, createdAt: -1 });
ClubCoachInvitationSchema.index({
  clubUserId: 1,
  coachUserId: 1,
  createdAt: -1,
});

// One live invitation per club/coach pair, whichever side sent it.
ClubCoachInvitationSchema.index(
  { clubUserId: 1, coachUserId: 1 },
  {
    unique: true,
    partialFilterExpression: { status: InvitationStatus.PENDING },
  },
);
