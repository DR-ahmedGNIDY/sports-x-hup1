import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  StoreCategory,
  StoreCategoryDocument,
} from '../schemas/category.schema';
import { slugify } from '../slug';
import { StoreImagesService } from '../store-images.service';
import { UpsertCategoryDto } from './dto/upsert-category.dto';

@Injectable()
export class StoreCategoriesService {
  constructor(
    @InjectModel(StoreCategory.name)
    private readonly categoryModel: Model<StoreCategory>,
    private readonly images: StoreImagesService,
  ) {}

  // Unpaginated on purpose: this is the storefront's navigation menu, and a
  // catalogue with enough top-level categories to need paging has a
  // navigation problem no page parameter fixes.
  async listActive(): Promise<StoreCategoryDocument[]> {
    return this.categoryModel
      .find({ isActive: true })
      .sort({ sortOrder: 1, _id: 1 })
      .exec();
  }

  async listAll(): Promise<StoreCategoryDocument[]> {
    return this.categoryModel.find().sort({ sortOrder: 1, _id: 1 }).exec();
  }

  // An indexed `_id` existence check rather than loading the document —
  // the product writes only need to know the category is real.
  async existsById(id: string): Promise<boolean> {
    if (!Types.ObjectId.isValid(id)) return false;
    return (await this.categoryModel.exists({ _id: id })) !== null;
  }

  async findBySlugOrThrow(slug: string): Promise<StoreCategoryDocument> {
    const category = await this.categoryModel.findOne({
      slug: slug.toLowerCase(),
      isActive: true,
    });
    if (!category) throw new NotFoundException('Category not found.');
    return category;
  }

  async create(dto: UpsertCategoryDto): Promise<StoreCategoryDocument> {
    const parentId = await this.resolveParent(dto.parentId);
    const slug = await this.allocateSlug(dto.name.en);
    return this.categoryModel.create({
      name: { en: dto.name.en, ar: dto.name.ar },
      slug,
      parentId,
      sortOrder: dto.sortOrder ?? 0,
      isActive: dto.isActive ?? true,
    });
  }

  async update(
    id: string,
    dto: UpsertCategoryDto,
  ): Promise<StoreCategoryDocument> {
    const category = await this.categoryModel.findById(id);
    if (!category) throw new NotFoundException('Category not found.');

    const parentId = await this.resolveParent(dto.parentId);
    // A category that is its own parent would make the nav walk forever.
    if (parentId && parentId.equals(category._id)) {
      throw new BadRequestException('A category cannot be its own parent.');
    }

    category.name = { en: dto.name.en, ar: dto.name.ar };
    category.parentId = parentId;
    if (dto.sortOrder !== undefined) category.sortOrder = dto.sortOrder;
    if (dto.isActive !== undefined) category.isActive = dto.isActive;
    // The slug is deliberately not regenerated from a renamed category:
    // it is a published URL, and rewriting it silently breaks every link
    // and every search result already pointing at it.
    return category.save();
  }

  // Deactivates rather than deletes, and only once nothing points here —
  // see the controller for why this is the only removal offered.
  async deactivate(id: string): Promise<StoreCategoryDocument> {
    const category = await this.categoryModel.findById(id);
    if (!category) throw new NotFoundException('Category not found.');
    category.isActive = false;
    return category.save();
  }

  // A category holds one image, so this replaces rather than appends. The
  // previous asset is deleted after the new one is saved: an orphaned
  // Cloudinary file costs storage, whereas deleting first and then failing
  // to save would leave the tile pointing at nothing.
  async setImage(
    id: string,
    file: Express.Multer.File,
  ): Promise<StoreCategoryDocument> {
    const category = await this.categoryModel.findById(id);
    if (!category) throw new NotFoundException('Category not found.');

    const previous = category.image?.publicId;
    category.image = await this.images.upload(
      file,
      `sportxhub/store/categories/${category._id.toString()}`,
    );
    const saved = await category.save();
    if (previous) await this.images.remove(previous);
    return saved;
  }

  private async resolveParent(
    parentId?: string,
  ): Promise<Types.ObjectId | undefined> {
    if (!parentId) return undefined;
    const parent = await this.categoryModel.exists({ _id: parentId });
    if (!parent) throw new BadRequestException('Parent category not found.');
    return new Types.ObjectId(parentId);
  }

  // Two categories called "Shorts" under different parents are legitimate,
  // so a taken slug gets a numeric suffix rather than a rejection. The
  // unique index is still the authority: if a concurrent create takes the
  // slug between this check and the insert, Mongo raises E11000 and the
  // caller sees a 409 rather than a silent second "shorts".
  private async allocateSlug(source: string): Promise<string> {
    const base = slugify(source) || 'category';
    for (let suffix = 0; suffix < 50; suffix++) {
      const candidate = suffix === 0 ? base : `${base}-${suffix + 1}`;
      const taken = await this.categoryModel.exists({ slug: candidate });
      if (!taken) return candidate;
    }
    throw new ConflictException(
      'Could not derive a unique slug for this category name.',
    );
  }
}
