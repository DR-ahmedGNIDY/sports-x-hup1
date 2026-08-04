import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SavedPlayerDocument = HydratedDocument<SavedPlayer>;

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'savedplayers',
})
export class SavedPlayer {
  // No standalone index here — the compound unique index below has
  // clubUserId as its leading field, so `find({ clubUserId })` (the
  // Saved Players list query) already uses it as a prefix. A separate
  // single-field index would just be duplicate write overhead.
  @Prop({ type: Types.ObjectId, required: true, ref: 'User' })
  clubUserId: Types.ObjectId;

  // Kept standalone: the roadmap calls this out explicitly for reverse
  // lookups ("how many clubs saved this player"), which query by
  // playerId alone — not a prefix of the compound index below.
  @Prop({
    type: Types.ObjectId,
    required: true,
    index: true,
    ref: 'PlayerProfile',
  })
  playerId: Types.ObjectId;
}

export const SavedPlayerSchema = SchemaFactory.createForClass(SavedPlayer);

// Prevents saving the same player twice at the database level, not just
// in application code (the roadmap's explicit acceptance criterion).
SavedPlayerSchema.index({ clubUserId: 1, playerId: 1 }, { unique: true });
