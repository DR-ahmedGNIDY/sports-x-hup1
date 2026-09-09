import { LocalizedText } from './schemas/localized-text.schema';
import { StoreCategoryDocument } from './schemas/category.schema';
import { CouponDocument } from './schemas/coupon.schema';
import { StoreOrderDocument } from './schemas/order.schema';
import { StoreProductDocument } from './schemas/product.schema';
import { ShippingZoneDocument } from './schemas/shipping-zone.schema';

// Sent as both halves rather than resolved server-side: the store front
// switches language without a round trip (locale lives in the client), and
// a cached response must not be language-specific.
function toLocalizedView(text: LocalizedText | undefined) {
  if (!text) return undefined;
  return { en: text.en, ar: text.ar };
}

export function toCategoryView(category: StoreCategoryDocument) {
  return {
    id: category._id.toString(),
    name: toLocalizedView(category.name),
    slug: category.slug,
    parentId: category.parentId?.toString(),
    image: category.image,
    sortOrder: category.sortOrder,
  };
}

// The card view: everything a grid or carousel tile renders, and nothing
// more. Variants in particular are omitted — a 40-tile listing would
// otherwise ship every size and colour of every product to draw a price.
export function toProductCardView(product: StoreProductDocument) {
  return {
    id: product._id.toString(),
    title: toLocalizedView(product.title),
    slug: product.slug,
    priceMinor: product.priceMinor,
    compareAtPriceMinor: product.compareAtPriceMinor,
    // Only the first image; the tile shows one.
    image: product.images[0],
    badge: product.badge,
    // Lets the card show "Sold out" without shipping the variant array.
    inStock: product.variants.some((variant) => variant.stock > 0),
  };
}

export function toProductDetailView(product: StoreProductDocument) {
  return {
    ...toProductCardView(product),
    description: toLocalizedView(product.description),
    categoryId: product.categoryId.toString(),
    images: product.images,
    variants: product.variants.map((variant) => ({
      id: variant._id?.toString(),
      size: variant.size,
      colour: variant.colour,
      sku: variant.sku,
      // The exact count is a merchant fact, not a customer one. Publishing
      // it invites "only 2 left" scraping and tells a competitor the
      // sell-through rate; the buyer only needs to know whether they can
      // add it to the cart.
      inStock: variant.stock > 0,
    })),
    tags: product.tags,
    isFeatured: product.isFeatured,
  };
}

// The admin table needs the merchant facts the public views deliberately
// withhold — real stock counts and the active flag.
export function toAdminProductView(product: StoreProductDocument) {
  return {
    ...toProductDetailView(product),
    isActive: product.isActive,
    variants: product.variants.map((variant) => ({
      id: variant._id?.toString(),
      size: variant.size,
      colour: variant.colour,
      sku: variant.sku,
      stock: variant.stock,
    })),
  };
}

export function toAdminCategoryView(category: StoreCategoryDocument) {
  return { ...toCategoryView(category), isActive: category.isActive };
}

export function toShippingZoneView(zone: ShippingZoneDocument) {
  return {
    id: zone._id.toString(),
    name: toLocalizedView(zone.name),
    code: zone.code,
    feeMinor: zone.feeMinor,
  };
}

export function toAdminShippingZoneView(zone: ShippingZoneDocument) {
  return { ...toShippingZoneView(zone), isActive: zone.isActive };
}

// One view for the customer and the merchant alike — an order has no field
// the buyer may not see. What differs is which orders each can reach, and
// that is decided by the service, not by hiding fields here.
export function toOrderView(order: StoreOrderDocument) {
  return {
    id: order._id.toString(),
    orderNumber: order.orderNumber,
    // Present only for an order placed while signed in; a guest order has
    // none, which is how the front end knows to offer the tracking form
    // rather than an order history.
    userId: order.userId?.toString(),
    email: order.email,
    status: order.status,
    lines: order.lines.map((line) => ({
      productId: line.productId.toString(),
      variantId: line.variantId.toString(),
      title: toLocalizedView(line.title),
      size: line.size,
      colour: line.colour,
      imageUrl: line.imageUrl,
      quantity: line.quantity,
      unitPriceMinor: line.unitPriceMinor,
    })),
    address: {
      fullName: order.address.fullName,
      phone: order.address.phone,
      governorateCode: order.address.governorateCode,
      governorateName: toLocalizedView(order.address.governorateName),
      city: order.address.city,
      street: order.address.street,
      notes: order.address.notes,
    },
    subtotalMinor: order.subtotalMinor,
    shippingFeeMinor: order.shippingFeeMinor,
    couponCode: order.couponCode,
    discountMinor: order.discountMinor,
    totalMinor: order.totalMinor,
    createdAt: order.get('createdAt') as Date,
  };
}

// Admin-only: coupons are never listed to customers, who only ever learn
// whether the one code they typed is valid.
export function toCouponView(coupon: CouponDocument) {
  return {
    id: coupon._id.toString(),
    code: coupon.code,
    type: coupon.type,
    value: coupon.value,
    minSubtotalMinor: coupon.minSubtotalMinor,
    maxRedemptions: coupon.maxRedemptions,
    redemptions: coupon.redemptions,
    startsAt: coupon.startsAt,
    endsAt: coupon.endsAt,
    isActive: coupon.isActive,
  };
}
