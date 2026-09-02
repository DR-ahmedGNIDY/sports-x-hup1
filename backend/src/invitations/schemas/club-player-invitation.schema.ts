import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export enum InvitationType {
  CLUB_TO_PLAYER = 'CLUB_TO_PLAYER',
  PLAYER_TO_CLUB = 'PLAYER_TO_CLUB',
}

export enum InvitationStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED',
}

/** PENDING is the only non-terminal state — see the plan's state machine. */
export const TERMINAL_INVITATION_STATUSES = [
  InvitationStatus.ACCEPTED,
  InvitationStatus.REJECTED,
  InvitationStatus.CANCELLED,
  InvitationStatus.EXPIRED,
];

export const INVITATION_MESSAGE_MAX_LENGTH = 500;
export const INVITATION_TTL_DAYS = 30;

export type ClubPlayerInvitationDocument =
  HydratedDocument<ClubPlayerInvitation>;

export function defaultExpiresAt(from: Date = new Date()): Date {
  return new Date(from.getTime() + INVITATION_TTL_DAYS * 24 * 60 * 60 * 1000);
}

// A club↔player invitation in either direction. This is the *pre*-relationship
// record; the relationship itself is ClubMembership, created only when a
// PENDING invitation is accepted.
@Schema({ timestamps: true, collection: 'club_player_invitations' })
export class ClubPlayerInvitation {
  @Prop({ required: true, enum: InvitationType })
  type: InvitationType;

  @Prop({
    required: true,
    enum: InvitationStatus,
    default: InvitationStatus.PENDING,
  })
  status: InvitationStatus;

  // The canonical pair, stored direction-independently so "is there already
  // something live between this club and this player?" is one indexed lookup
  // no matter who started it.
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  clubUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  playerUserId: Types.ObjectId;

  // Derived from `type` by the service and never accepted from a request
  // body. Stored (rather than recomputed per query) so the inbox and outbox
  // are straight index prefixes instead of a $or over both roles.
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

export const ClubPlayerInvitationSchema =
  SchemaFactory.createForClass(ClubPlayerInvitation);

// Inbox and outbox: recipient/sender + status filter + newest-first sort, all
// served from one index each.
ClubPlayerInvitationSchema.index({
  recipientUserId: 1,
  status: 1,
  createdAt: -1,
});
ClubPlayerInvitationSchema.index({ senderUserId: 1, status: 1, createdAt: -1 });

// Relationship history between one club and one player, in either direction.
// `createdAt` is part of the key rather than a bare { clubUserId, playerUserId }
// pair for two reasons: history is always read newest-first, and a bare pair
// would collide with the partial unique index below — same key, so Mongo would
// carry two near-identical indexes and Mongoose would (rightly) warn about it.
// This key still covers `{ clubUserId, playerUserId }` lookups as a prefix.
ClubPlayerInvitationSchema.index({
  clubUserId: 1,
  playerUserId: 1,
  createdAt: -1,
});

ClubPlayerInvitationSchema.index({ type: 1, status: 1 });
ClubPlayerInvitationSchema.index({ createdAt: -1 });

// The expiry sweep (markExpired) — without this it would scan every
// invitation ever created to find the handful that just lapsed.
ClubPlayerInvitationSchema.index({ status: 1, expiresAt: 1 });

// The duplicate-pending rule, enforced by the database rather than by a
// read-then-write that two concurrent requests could both pass. Partial on
// PENDING so the same pair can invite each other again after a rejection or
// a departure; direction-independent (no `type` in the key) so a club and a
// player can't end up with two live invitations pointing at each other.
ClubPlayerInvitationSchema.index(
  { clubUserId: 1, playerUserId: 1 },
  {
    unique: true,
    partialFilterExpression: { status: InvitationStatus.PENDING },
  },
);
