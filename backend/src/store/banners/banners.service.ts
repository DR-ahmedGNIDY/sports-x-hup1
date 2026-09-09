import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { StoreBanner, StoreBannerDocument } from '../schemas/banner.schema';
import { StoreImagesService } from '../store-images.service';
import { BannerSlot } from './banner-slot';
import { UpsertBannerDto } from './dto/upsert-banner.dto';

@Injectable()
export class BannersService {
  constructor(
    @InjectModel(StoreBanner.name)
    private readonly bannerModel: Model<StoreBanner>,
    private readonly images: StoreImagesService,
  ) {}

  /// What the hero renders.
  ///
  /// A banner with no desktop image is withheld even when it is active: it
  /// was created but never finished, and an empty slide in a rotation reads
  /// as the page being broken. The dashboard shows those rows so the
  /// merchant can see why one is missing.
  async listPublished(): Promise<StoreBannerDocument[]> {
    return this.bannerModel
      .find({ isActive: true, 'desktopImage.secureUrl': { $exists: true } })
      .sort({ sortOrder: 1, _id: 1 })
      .exec();
  }

  async listAll(): Promise<StoreBannerDocument[]> {
    return this.bannerModel.find().sort({ sortOrder: 1, _id: 1 }).exec();
  }

  async findByIdOrThrow(id: string): Promise<StoreBannerDocument> {
    const banner = await this.bannerModel.findById(id);
    if (!banner) throw new NotFoundException('Banner not found.');
    return banner;
  }

  // Created empty, then filled by the image endpoints — the images are
  // multipart and cannot travel in this JSON body, and a banner needs an id
  // before its Cloudinary folder can be named after it.
  async create(dto: UpsertBannerDto): Promise<StoreBannerDocument> {
    return this.bannerModel.create({
      alt: dto.alt ? { en: dto.alt.en, ar: dto.alt.ar } : undefined,
      linkPath: dto.linkPath,
      sortOrder: dto.sortOrder ?? 0,
      isActive: dto.isActive ?? true,
    });
  }

  async update(id: string, dto: UpsertBannerDto): Promise<StoreBannerDocument> {
    const banner = await this.findByIdOrThrow(id);
    banner.alt = dto.alt ? { en: dto.alt.en, ar: dto.alt.ar } : undefined;
    banner.linkPath = dto.linkPath;
    if (dto.sortOrder !== undefined) banner.sortOrder = dto.sortOrder;
    if (dto.isActive !== undefined) banner.isActive = dto.isActive;
    return banner.save();
  }

  /// Replaces one of the two images. The previous asset is deleted only
  /// after the new one is saved: an orphan in Cloudinary costs storage,
  /// whereas deleting first and then failing to save would leave the hero
  /// pointing at nothing.
  async setImage(
    id: string,
    slot: BannerSlot,
    file: Express.Multer.File,
  ): Promise<StoreBannerDocument> {
    const banner = await this.findByIdOrThrow(id);
    const previous = this.imageAt(banner, slot)?.publicId;

    const uploaded = await this.images.upload(
      file,
      `sportxhub/store/banners/${banner._id.toString()}`,
    );
    if (slot === BannerSlot.DESKTOP) {
      banner.desktopImage = uploaded;
    } else {
      banner.mobileImage = uploaded;
    }

    const saved = await banner.save();
    if (previous) await this.images.remove(previous);
    return saved;
  }

  /// Clears one image. The desktop one cannot be cleared on its own — it is
  /// what makes a banner publishable, so removing it would silently unlist
  /// the banner rather than doing what was asked.
  async removeImage(
    id: string,
    slot: BannerSlot,
  ): Promise<StoreBannerDocument> {
    if (slot === BannerSlot.DESKTOP) {
      throw new BadRequestException(
        'The desktop image cannot be removed — replace it, or deactivate the banner.',
      );
    }

    const banner = await this.findByIdOrThrow(id);
    const previous = banner.mobileImage?.publicId;
    if (!previous) return banner;

    banner.mobileImage = undefined;
    const saved = await banner.save();
    await this.images.remove(previous);
    return saved;
  }

  /// Deactivates rather than deletes, matching the rest of the store: a
  /// banner is cheap to keep and a merchant re-running a campaign should
  /// not have to re-upload it.
  async deactivate(id: string): Promise<StoreBannerDocument> {
    const banner = await this.findByIdOrThrow(id);
    banner.isActive = false;
    return banner.save();
  }

  private imageAt(banner: StoreBannerDocument, slot: BannerSlot) {
    return slot === BannerSlot.DESKTOP
      ? banner.desktopImage
      : banner.mobileImage;
  }
}
