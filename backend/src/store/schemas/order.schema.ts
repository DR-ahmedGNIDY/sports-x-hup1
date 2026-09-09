import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { OrderStatus } from '../order-status.enum';
import { LocalizedText, LocalizedTextSchema } from './localized-text.schema';

export type StoreOrderDocument = HydratedDocument<StoreOrder>;

/// A line as it was at the moment of purchase, not a pointer to a product
/// that keeps changing.
///
/// The title, the price and the variant are all copied in. A product renamed
/// or repriced next season must not rewrite what a customer already agreed
/// to pay — an order is a record of a past agreement, and a receipt that
/// silently reflows is not a receipt.
@Schema({ _id: false, timestamps: false })
export class OrderLine {
  @Prop({ type: Types.ObjectId, required: true, ref: 'StoreProduct' })
  productId: Types.ObjectId;

  // Which variant of that product. Free-text size/colour are snapshotted
  // alongside it so the line still reads correctly if the variant is later
  // removed from the product.
  @Prop({ type: Types.ObjectId, required: true })
  variantId: Types.ObjectId;

  @Prop({ type: LocalizedTextSchema, required: true })
  title: LocalizedText;

  @Prop({ trim: true })
  size?: string;

  @Prop({ trim: true })
  colour?: string;

  @Prop({ trim: true })
  imageUrl?: string;

  @Prop({ required: true, min: 1 })
  quantity: number;

  // Piastres, and the price *charged*, resolved on the server at checkout —
  // never a number the client sent.
  @Prop({ required: true, min: 0 })
  unitPriceMinor: number;
}
export const OrderLineSchema = SchemaFactory.createForClass(OrderLine);

/// Where it goes. Held on the order rather than referenced from a saved
/// address book: a guest has no address book, and a registered customer who
/// later edits a saved address must not retroactively change where a past
/// order was sent.
@Schema({ _id: false, timestamps: false })
export class ShippingAddress {
  @Prop({ required: true, trim: true })
  fullName: string;

  @Prop({ required: true, trim: true })
  phone: string;

  // The zone `code`, not its ObjectId — a stable string that stays readable
  // in an exported order and survives the zone document being edited.
  @Prop({ required: true, trim: true, lowercase: true })
  governorateCode: string;

  // Snapshotted for the same reason as the line titles: so a printed order
  // still names its governorate without a join, in both languages.
  @Prop({ type: LocalizedTextSchema, required: true })
  governorateName: LocalizedText;

  @Prop({ required: true, trim: true })
  city: string;

  @Prop({ required: true, trim: true })
  street: string;

  @Prop({ trim: true })
  notes?: string;
}
export const ShippingAddressSchema =
  SchemaFactory.createForClass(ShippingAddress);

@Schema({ timestamps: true, collection: 'storeorders' })
export class StoreOrder {
  // Human-readable and shareable ("ORD-000123"), allocated from the same
  // atomic counter the player and club codes use. This is what the customer
  // quotes on the phone; the Mongo _id never leaves the server.
  @Prop({ required: true, unique: true, trim: true })
  orderNumber: string;

  // Absent for a guest order — which is the whole point of allowing guest
  // checkout. Indexed sparsely so the many guest orders holding no value
  // here don't all sit in one index bucket.
  @Prop({ type: Types.ObjectId, ref: 'User', index: true, sparse: true })
  userId?: Types.ObjectId;

  // Always captured, for both guests and signed-in customers: it is how the
  // order is tracked and how the merchant makes contact. For a guest it is
  // also half of the credential that retrieves the order — see
  // OrdersService.trackForGuest.
  @Prop({ required: true, trim: true, lowercase: true, index: true })
  email: string;

  @Prop({ type: [OrderLineSchema], required: true })
  lines: OrderLine[];

  @Prop({ type: ShippingAddressSchema, required: true })
  address: ShippingAddress;

  // All of these are stored rather than derived on read. The fee, the
  // coupon's value and the product prices can all change after the fact; a
  // total recomputed at render time would quietly disagree with what was
  // collected at the door.
  @Prop({ required: true, min: 0 })
  subtotalMinor: number;

  @Prop({ required: true, min: 0 })
  shippingFeeMinor: number;

  /// The code as it was claimed, upper-cased. Kept on the order so a receipt
  /// can explain the discount without a join, and so cancelling knows which
  /// coupon to hand a redemption back to.
  @Prop({ trim: true, uppercase: true })
  couponCode?: string;

  /// What the code took off, in piastres.
  @Prop({ default: 0, min: 0 })
  discountMinor: number;

  @Prop({ required: true, min: 0 })
  totalMinor: number;

  @Prop({
    type: String,
    enum: OrderStatus,
    required: true,
    default: OrderStatus.PENDING,
    index: true,
  })
  status: OrderStatus;
}

export const StoreOrderSchema = SchemaFactory.createForClass(StoreOrder);

// The admin queue: orders of one status, newest first.
StoreOrderSchema.index({ status: 1, createdAt: -1 });

// "My orders" for a signed-in customer.
StoreOrderSchema.index({ userId: 1, createdAt: -1 });
