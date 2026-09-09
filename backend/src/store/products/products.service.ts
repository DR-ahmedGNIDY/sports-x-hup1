import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';
import { StoreCategoriesService } from '../categories/categories.service';
import { StoreImagesService } from '../store-images.service';
import { StoreProduct, StoreProductDocument } from '../schemas/product.schema';
import { slugify } from '../slug';
import { ListProductsDto, ProductSort } from './dto/list-products.dto';
import { UpsertProductDto } from './dto/upsert-product.dto';

const PRODUCT_LIST_PAGE_SIZE = 24;

// Bounded so one product cannot be given a gallery large enough to make its
// own detail response the slowest thing in the store.
const MAX_PRODUCT_IMAGES = 10;

export interface ProductPaginatedResult {
  items: StoreProductDocument[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class StoreProductsService {
  constructor(
    @InjectModel(StoreProduct.name)
    private readonly productModel: Model<StoreProduct>,
    private readonly categories: StoreCategoriesService,
    private readonly images: StoreImagesService,
  ) {}

  // The storefront listing. `includeInactive` is what separates this from
  // the admin table — same filters, same paging, one flag, rather than two
  // query builders that drift apart.
  async list(
    dto: ListProductsDto,
    includeInactive = false,
  ): Promise<ProductPaginatedResult> {
    const filter: FilterQuery<StoreProduct> = {};
    if (!includeInactive) filter.isActive = true;

    if (dto.categorySlug) {
      const category = await this.categories.findBySlugOrThrow(
        dto.categorySlug,
      );
      filter.categoryId = category._id;
    } else if (dto.categoryId) {
      filter.categoryId = new Types.ObjectId(dto.categoryId);
    }

    if (dto.featured !== undefined) filter.isFeatured = dto.featured;

    if (dto.minPriceMinor !== undefined || dto.maxPriceMinor !== undefined) {
      if (
        dto.minPriceMinor !== undefined &&
        dto.maxPriceMinor !== undefined &&
        dto.minPriceMinor > dto.maxPriceMinor
      ) {
        throw new BadRequestException(
          'minPriceMinor cannot exceed maxPriceMinor.',
        );
      }
      const priceRange: Record<string, number> = {};
      if (dto.minPriceMinor !== undefined) {
        priceRange.$gte = dto.minPriceMinor;
      }
      if (dto.maxPriceMinor !== undefined) {
        priceRange.$lte = dto.maxPriceMinor;
      }
      filter.priceMinor = priceRange;
    }

    // Size and colour live on the variant subdocuments, so both conditions
    // have to hold on the *same* variant — `$elemMatch`, not two parallel
    // dotted paths, which would match a product carrying the size on one
    // variant and the colour on another.
    const variantMatch: Record<string, unknown> = {};
    if (dto.size) variantMatch.size = dto.size;
    if (dto.colour) variantMatch.colour = dto.colour;
    if (Object.keys(variantMatch).length > 0) {
      filter.variants = { $elemMatch: variantMatch };
    }

    if (dto.search) {
      // The text index covers both languages and both fields, and `$text`
      // also stems, which a regex would not: "shorts" finds "short".
      filter.$text = { $search: dto.search };
    }

    const page = dto.page ?? 1;
    const skip = (page - 1) * PRODUCT_LIST_PAGE_SIZE;

    const [items, total] = await Promise.all([
      this.productModel
        .find(filter)
        .sort(this.sortSpec(dto.sort))
        .skip(skip)
        .limit(PRODUCT_LIST_PAGE_SIZE)
        .exec(),
      this.productModel.countDocuments(filter).exec(),
    ]);

    return { items, page, pageSize: PRODUCT_LIST_PAGE_SIZE, total };
  }

  async findBySlugOrThrow(slug: string): Promise<StoreProductDocument> {
    const product = await this.productModel.findOne({
      slug: slug.toLowerCase(),
      isActive: true,
    });
    if (!product) throw new NotFoundException('Product not found.');
    return product;
  }

  async findByIdOrThrow(id: string): Promise<StoreProductDocument> {
    const product = await this.productModel.findById(id);
    if (!product) throw new NotFoundException('Product not found.');
    return product;
  }

  async create(dto: UpsertProductDto): Promise<StoreProductDocument> {
    this.assertPricesCoherent(dto);
    await this.assertCategoryExists(dto.categoryId);
    const slug = await this.allocateSlug(dto.title.en);

    return this.productModel.create({
      title: { en: dto.title.en, ar: dto.title.ar },
      slug,
      description: dto.description
        ? { en: dto.description.en, ar: dto.description.ar }
        : undefined,
      categoryId: new Types.ObjectId(dto.categoryId),
      priceMinor: dto.priceMinor,
      compareAtPriceMinor: dto.compareAtPriceMinor,
      // Images are attached by their own upload endpoint, not by this JSON
      // body — they arrive as multipart and go to Cloudinary first.
      images: [],
      variants: dto.variants ?? [],
      badge: dto.badge,
      tags: dto.tags ?? [],
      isFeatured: dto.isFeatured ?? false,
      isActive: dto.isActive ?? true,
    });
  }

  async update(
    id: string,
    dto: UpsertProductDto,
  ): Promise<StoreProductDocument> {
    this.assertPricesCoherent(dto);
    await this.assertCategoryExists(dto.categoryId);

    const product = await this.findByIdOrThrow(id);
    product.title = { en: dto.title.en, ar: dto.title.ar };
    product.description = dto.description
      ? { en: dto.description.en, ar: dto.description.ar }
      : undefined;
    product.categoryId = new Types.ObjectId(dto.categoryId);
    product.priceMinor = dto.priceMinor;
    product.compareAtPriceMinor = dto.compareAtPriceMinor;
    if (dto.variants) product.set('variants', dto.variants);
    product.badge = dto.badge;
    if (dto.tags) product.tags = dto.tags;
    if (dto.isFeatured !== undefined) product.isFeatured = dto.isFeatured;
    if (dto.isActive !== undefined) product.isActive = dto.isActive;
    // The slug is deliberately not regenerated from a renamed product: it
    // is a published URL, and rewriting it silently breaks every link and
    // every search result already pointing at it.
    return product.save();
  }

  // Unlisting, not deleting. An order placed last week still has to render
  // the product it was for, so the document has to outlive its removal from
  // the storefront.
  async deactivate(id: string): Promise<StoreProductDocument> {
    const product = await this.findByIdOrThrow(id);
    product.isActive = false;
    return product.save();
  }

  // Appended, not replaced: a gallery is built one upload at a time, and
  // the first image is the one every tile shows, so order matters and the
  // merchant controls it by upload order (and by removing and re-adding).
  async addImage(
    id: string,
    file: Express.Multer.File,
  ): Promise<StoreProductDocument> {
    const product = await this.findByIdOrThrow(id);
    if (product.images.length >= MAX_PRODUCT_IMAGES) {
      throw new BadRequestException(
        `A product can hold at most ${MAX_PRODUCT_IMAGES} images.`,
      );
    }

    const image = await this.images.upload(
      file,
      `sportxhub/store/products/${product._id.toString()}`,
    );
    product.images.push(image);
    return product.save();
  }

  // The document is saved first: an image still listed on a product whose
  // Cloudinary asset is gone renders as a broken tile, whereas an orphaned
  // Cloudinary asset only costs storage. So the visible failure is the one
  // that is ordered away.
  async removeImage(
    id: string,
    publicId: string,
  ): Promise<StoreProductDocument> {
    const product = await this.findByIdOrThrow(id);
    const image = product.images.find((it) => it.publicId === publicId);
    if (!image) throw new NotFoundException('Image not found on this product.');

    product.images = product.images.filter((it) => it.publicId !== publicId);
    const saved = await product.save();
    await this.images.remove(publicId);
    return saved;
  }

  private sortSpec(sort?: ProductSort): Record<string, 1 | -1> {
    switch (sort) {
      case ProductSort.PRICE_ASC:
        // `_id` breaks the tie so a page boundary cannot repeat or skip a
        // product when many share a price — which, in a catalogue with
        // round price points, is most of them.
        return { priceMinor: 1, _id: 1 };
      case ProductSort.PRICE_DESC:
        return { priceMinor: -1, _id: 1 };
      default:
        return { createdAt: -1, _id: 1 };
    }
  }

  private assertPricesCoherent(dto: UpsertProductDto): void {
    if (
      dto.compareAtPriceMinor !== undefined &&
      dto.compareAtPriceMinor <= dto.priceMinor
    ) {
      throw new BadRequestException(
        'compareAtPriceMinor must be greater than priceMinor — it is the struck-through original price.',
      );
    }
  }

  private async assertCategoryExists(categoryId: string): Promise<void> {
    const exists = await this.categories.existsById(categoryId);
    if (!exists) throw new BadRequestException('Category not found.');
  }

  // Two products called "Black Cargo Shorts" a season apart are legitimate,
  // so a taken slug gets a numeric suffix rather than a rejection. The
  // unique index remains the authority: if a concurrent create takes the
  // slug between this check and the insert, Mongo raises E11000 and the
  // caller sees a 409 rather than a silent duplicate.
  private async allocateSlug(source: string): Promise<string> {
    const base = slugify(source) || 'product';
    for (let suffix = 0; suffix < 50; suffix++) {
      const candidate = suffix === 0 ? base : `${base}-${suffix + 1}`;
      const taken = await this.productModel.exists({ slug: candidate });
      if (!taken) return candidate;
    }
    throw new ConflictException(
      'Could not derive a unique slug for this product title.',
    );
  }
}
