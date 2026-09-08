import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { LocalizedText, LocalizedTextSchema } from './localized-text.schema';

export type StoreCategoryDocument = HydratedDocument<StoreCategory>;

@Schema({ _id: false, timestamps: false })
export class CategoryImage {
  @Prop({ required: true })
  publicId: string;

  @Prop({ required: true })
  secureUrl: string;
}
export const CategoryImageSchema = SchemaFactory.createForClass(CategoryImage);

@Schema({ timestamps: true, collection: 'storecategories' })
export class StoreCategory {
  @Prop({ type: LocalizedTextSchema, required: true })
  name: LocalizedText;

  // The URL segment (`/store/c/men-tops`). Unique because it addresses the
  // category publicly — two categories resolving to one URL is a bug the
  // database should refuse rather than a race the service has to notice.
  @Prop({ required: true, unique: true, trim: true, lowercase: true })
  slug: string;

  // One level of nesting only, mirroring the reference storefront's
  // Men > Tops / Bottoms menu. A self-reference rather than a `children`
  // array so moving a child is a single-document write.
  @Prop({ type: Types.ObjectId, ref: StoreCategory.name, index: true })
  parentId?: Types.ObjectId;

  @Prop({ type: CategoryImageSchema })
  image?: CategoryImage;

  // Menu order is editorial, not alphabetical — "New Arrivals" leads the nav
  // on every storefront of this kind and would sort near the middle.
  @Prop({ default: 0 })
  sortOrder: number;

  // Hiding a category is how a seasonal collection leaves the storefront.
  // Deleting it would orphan every product pointing at it.
  @Prop({ default: true, index: true })
  isActive: boolean;
}

export const StoreCategorySchema = SchemaFactory.createForClass(StoreCategory);

// The storefront nav asks for exactly this: the active categories, in
// editorial order. Without the compound index that is a collection scan on
// every page load, since the nav is on every page.
StoreCategorySchema.index({ isActive: 1, sortOrder: 1 });
