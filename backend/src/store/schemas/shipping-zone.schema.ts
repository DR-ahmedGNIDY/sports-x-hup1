import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { LocalizedText, LocalizedTextSchema } from './localized-text.schema';

export type ShippingZoneDocument = HydratedDocument<ShippingZone>;

/// One city inside a governorate, priced on its own.
///
/// Embedded rather than a separate collection: a city has no existence or
/// audience outside its governorate, and the dashboard edits a governorate's
/// cities as one group. Code is a slug, stable like a zone's — an order that
/// picked a city keeps pointing at it even if the display name changes.
@Schema({ _id: false, timestamps: false })
export class ShippingCity {
  @Prop({ type: LocalizedTextSchema, required: true })
  name: LocalizedText;

  @Prop({ required: true, trim: true, lowercase: true })
  code: string;

  @Prop({ required: true, min: 0 })
  feeMinor: number;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: 0 })
  sortOrder: number;
}
export const ShippingCitySchema = SchemaFactory.createForClass(ShippingCity);

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

  // Piastres, like every other amount in the store — see StoreProduct. Also
  // the fee for any city not broken out below, so pricing a governorate's
  // cities one by one can happen gradually without blocking checkout.
  @Prop({ required: true, min: 0 })
  feeMinor: number;

  // How a governorate stops being served without deleting a row that past
  // orders still point at.
  @Prop({ default: true, index: true })
  isActive: boolean;

  @Prop({ default: 0 })
  sortOrder: number;

  // Empty until the merchant prices this governorate city by city; once any
  // city here is active, checkout asks for one instead of taking the flat
  // fee above.
  @Prop({ type: [ShippingCitySchema], default: [] })
  cities: ShippingCity[];
}

export const ShippingZoneSchema = SchemaFactory.createForClass(ShippingZone);

// The checkout's governorate picker asks for exactly this.
ShippingZoneSchema.index({ isActive: 1, sortOrder: 1 });
