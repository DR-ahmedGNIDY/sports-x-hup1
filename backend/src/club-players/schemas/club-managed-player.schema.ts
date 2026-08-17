import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ClubManagedPlayerDocument = HydratedDocument<ClubManagedPlayer>;

// Ownership record for a player account a club created directly (as
// opposed to a self-registered player, or the SavedPlayer favorite/
// bookmark relationship) — every club-players endpoint checks this before
// touching a player's account or profile, so a club can only manage
// players it created.
@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'club_managed_players',
})
export class ClubManagedPlayer {
  @Prop({ type: Types.ObjectId, required: true, unique: true, ref: 'User' })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true, index: true, ref: 'User' })
  clubId: Types.ObjectId;

  // Cached at creation time so the wa.me link can be built from this
  // collection alone, without joining back to the Countries collection.
  @Prop({ required: true })
  dialCode: string;
}

export const ClubManagedPlayerSchema =
  SchemaFactory.createForClass(ClubManagedPlayer);

// No separate { clubId, userId } compound index here (release-audit P2):
// `userId` above is already `unique: true` on its own — a player can be
// managed by at most one club, ever — so a compound index over the same
// pair can never reject anything the single-field index wouldn't already
// reject. It was pure duplicate write overhead.
