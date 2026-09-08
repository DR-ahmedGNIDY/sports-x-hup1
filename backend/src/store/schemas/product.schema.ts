import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { ProductBadge } from '../product-badge.enum';
import { LocalizedText, LocalizedTextSchema } from './localized-text.schema';

export type StoreProductDocument = HydratedDocument<StoreProduct>;

@Schema({ _id: false, timestamps: false })
export class ProductImage {
  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;
}
export const ProductImageSchema = SchemaFactory.createForClass(ProductImage);

/// One buyable combination — it is the variant that carries stock, not the
/// product, because "Black / L is sold out" is the answer the cart needs.
///
/// `size` and `colour` are free text rather than enums: the reference
/// storefront alone runs S–XXL, EU shoe numbers, and one-size accessories,
/// and an enum would have to be redeployed for each new range.
@Schema({ _id: true, timestamps: false })
export class ProductVariant {
  // Assigned by Mongoose (`_id: true` above), not by us — declared only so
  // it is visible to TypeScript. The cart addresses a variant by this id,
  // since size and colour are free text and make a poor key.
  _id?: Types.ObjectId;

  @Prop({ trim: true })
  size?: string;

  @Prop({ trim: true })
  colour?: string;

  // The merchant's own code. Unique per product, not globally: two products
  // legitimately share a supplier SKU, and enforcing global uniqueness would
  // reject that for no benefit.
  @Prop({ trim: true })
  sku?: string;

  @Prop({ required: true, default: 0, min: 0 })
  stock: number;
}
export const ProductVariantSchema =
  SchemaFactory.createForClass(ProductVariant);

@Schema({ timestamps: true, collection: 'storeproducts' })
export class StoreProduct {
  @Prop({ type: LocalizedTextSchema, required: true })
  title: LocalizedText;

  @Prop({ required: true, unique: true, trim: true, lowercase: true })
  slug: string;

  @Prop({ type: LocalizedTextSchema })
  description?: LocalizedText;

  @Prop({
    type: Types.ObjectId,
    ref: 'StoreCategory',
    required: true,
    index: true,
  })
  categoryId: Types.ObjectId;

  // Money is stored in piastres — the integer minor unit — and never as a
  // float. 449.90 has no exact binary representation, so a float total
  // drifts by fractions of a piastre across a cart and then disagrees with
  // the payment provider's own arithmetic. The API speaks minor units too;
  // formatting is the front end's job, where the locale already lives.
  @Prop({ required: true, min: 0 })
  priceMinor: number;

  // The struck-through "was" price. Optional, and only meaningful when it is
  // above `priceMinor` — the service refuses the inverse rather than letting
  // a card advertise a markup as a discount.
  @Prop({ min: 0 })
  compareAtPriceMinor?: number;

  @Prop({ type: [ProductImageSchema], default: [] })
  images: ProductImage[];

  @Prop({ type: [ProductVariantSchema], default: [] })
  variants: ProductVariant[];

  @Prop({ type: String, enum: ProductBadge })
  badge?: ProductBadge;

  @Prop({ type: [String], default: [], index: true })
  tags: string[];

  // Drives the "New Arrivals" / featured carousels on the home page, which
  // are curated rather than derived from creation date.
  @Prop({ default: false, index: true })
  isFeatured: boolean;

  // Unlisting, not deletion — an inactive product still has to resolve for
  // the order history of everyone who already bought it.
  @Prop({ default: true, index: true })
  isActive: boolean;
}

export const StoreProductSchema = SchemaFactory.createForClass(StoreProduct);

// The category listing page — the store's most-hit query after the home
// page — filters on both fields and sorts by recency.
StoreProductSchema.index({ isActive: 1, categoryId: 1, createdAt: -1 });

// The home page's featured carousels.
StoreProductSchema.index({ isActive: 1, isFeatured: 1, createdAt: -1 });

// Search covers both languages in one index. Weighted towards the title so
// a query matching a product's name outranks one merely mentioned in
// another product's description.
StoreProductSchema.index(
  {
    'title.en': 'text',
    'title.ar': 'text',
    'description.en': 'text',
    'description.ar': 'text',
  },
  {
    weights: {
      'title.en': 10,
      'title.ar': 10,
      'description.en': 1,
      'description.ar': 1,
    },
    name: 'store_product_text',
  },
);
