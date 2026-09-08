import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { LocalizedText, LocalizedTextSchema } from './localized-text.schema';

export type ShippingZoneDocument = HydratedDocument<ShippingZone>;

/// One Egyptian governorate and what it costs to ship there.
///
/// A collection rather than a constant table because the fee is a commercial
/// decision the merchant changes without a deploy — a fuel rise or a new
/// courier contract should be an edit in the dashboard, not a release.
@Schema({ timestamps: true, collection: 'storeshippingzones' })
export class ShippingZone {
  @Prop({ type: LocalizedTextSchema, required: true })
  name: LocalizedText;

  // Stable machine identity ("cairo", "giza"). The order stores this, so it
  // must not change once orders reference it; renaming the display name is
  // safe, renaming the code is not.
  @Prop({ required: true, unique: true, trim: true, lowercase: true })
  code: string;

  // Piastres, like every other amount in the store — see StoreProduct.
  @Prop({ required: true, min: 0 })
  feeMinor: number;

  // How a governorate stops being served without deleting a row that past
  // orders still point at.
  @Prop({ default: true, index: true })
  isActive: boolean;

  @Prop({ default: 0 })
  sortOrder: number;
}

export const ShippingZoneSchema = SchemaFactory.createForClass(ShippingZone);

// The checkout's governorate picker asks for exactly this.
ShippingZoneSchema.index({ isActive: 1, sortOrder: 1 });
