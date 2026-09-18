import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { resourceTypeFor, validateMediaFile } from '../common/media-file';
import {
  MediaType,
  ProfileVisibility,
} from '../players/schemas/player-profile.schema';
import {
  PublicCodePrefix,
  PublicCodesService,
} from '../public-codes/public-codes.service';
import { SearchCoachesDto } from './dto/search-coaches.dto';
import { UpdateCoachProfileDto } from './dto/update-coach-profile.dto';
import {
  CoachProfile,
  CoachProfileDocument,
} from './schemas/coach-profile.schema';

const SEARCH_PAGE_SIZE = 20;

// Same ceiling as a player's embedded arrays: every item lives inside the
// profile document itself.
const MAX_EMBEDDED_ARRAY_ITEMS = 30;

/** The CV's repeatable sections — each one an embedded array of subdocs. */
export type CoachCvSection =
  'certifications' | 'experience' | 'achievements' | 'socialLinks';

const SECTION_NOT_FOUND: Record<CoachCvSection, string> = {
  certifications: 'Certification not found.',
  experience: 'Experience entry not found.',
  achievements: 'Achievement not found.',
  socialLinks: 'Social link not found.',
};

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

type SubdocArray = { _id?: Types.ObjectId }[];

export interface CoachSearchResult {
  items: CoachProfileDocument[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class CoachesService {
  constructor(
    @InjectModel(CoachProfile.name)
    private readonly coachProfileModel: Model<CoachProfile>,
    private readonly cloudinary: CloudinaryService,
    private readonly publicCodes: PublicCodesService,
  ) {}

  // Atomic upsert — see PlayersService.getOrCreateForUser for why.
  async getOrCreateForUser(userId: string): Promise<CoachProfileDocument> {
    const profile = await this.coachProfileModel.findOneAndUpdate(
      { userId },
      { $setOnInsert: { userId } },
      { new: true, upsert: true },
    );
    return this.ensurePublicCode(profile);
  }

  private async ensurePublicCode(
    profile: CoachProfileDocument,
  ): Promise<CoachProfileDocument> {
    if (profile.publicCode) return profile;

    const publicCode = await this.publicCodes.allocate(PublicCodePrefix.COACH);
    const updated = await this.coachProfileModel.findOneAndUpdate(
      { _id: profile._id, publicCode: { $in: [null, undefined] } },
      { $set: { publicCode } },
      { new: true },
    );
    return updated ?? (await this.coachProfileModel.findById(profile._id))!;
  }

  findByUserId(userId: string): Promise<CoachProfileDocument | null> {
    return this.coachProfileModel.findOne({ userId });
  }

  findManyByUserIds(userIds: string[]): Promise<CoachProfileDocument[]> {
    return this.coachProfileModel.find({ userId: { $in: userIds } });
  }

  async findPublicByIdOrThrow(id: string): Promise<CoachProfileDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Coach not found.');
    }
    const profile = await this.coachProfileModel.findById(id);
    if (!profile || profile.visibility !== ProfileVisibility.PUBLIC) {
      throw new NotFoundException('Coach not found.');
    }
    return profile;
  }

  // PUBLIC-only, like the player lookup: a code is not a way around a
  // coach's visibility setting.
  async findPublicByCodeOrThrow(code: string): Promise<CoachProfileDocument> {
    const normalized = PublicCodesService.normalizeFor(
      code,
      PublicCodePrefix.COACH,
    );
    if (!normalized) {
      throw new NotFoundException('Coach not found.');
    }
    const profile = await this.coachProfileModel.findOne({
      publicCode: normalized,
    });
    if (!profile || profile.visibility !== ProfileVisibility.PUBLIC) {
      throw new NotFoundException('Coach not found.');
    }
    return profile;
  }

  async search(dto: SearchCoachesDto): Promise<CoachSearchResult> {
    const filter: Record<string, unknown> = {
      visibility: ProfileVisibility.PUBLIC,
    };
    if (dto.search && dto.search.trim()) {
      // Token by token across both name fields — same reasoning as
      // PlayersService.search.
      const tokens = dto.search.trim().split(/\s+/).filter(Boolean);
      filter.$and = tokens.map((token) => {
        const regex = { $regex: escapeRegex(token), $options: 'i' };
        return { $or: [{ firstName: regex }, { lastName: regex }] };
      });
    }
    if (dto.country) filter.country = dto.country;
    if (dto.sport) filter.sport = dto.sport;

    const page = dto.page ?? 1;
    const [items, total] = await Promise.all([
      this.coachProfileModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * SEARCH_PAGE_SIZE)
        .limit(SEARCH_PAGE_SIZE),
      this.coachProfileModel.countDocuments(filter),
    ]);
    return { items, page, pageSize: SEARCH_PAGE_SIZE, total };
  }

  async updateProfile(
    userId: string,
    dto: UpdateCoachProfileDto,
  ): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    // `contact` merged field by field so a partial update doesn't wipe the
    // fields it left out — same as the player editor.
    const { contact, dateOfBirth, ...rest } = dto;
    Object.assign(profile, rest);
    if (contact) {
      Object.assign(profile.contact, contact);
    }
    if (dateOfBirth) {
      profile.dateOfBirth = new Date(dateOfBirth);
    }
    await profile.save();
    return profile;
  }

  async updateVisibility(
    userId: string,
    visibility: ProfileVisibility,
  ): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    profile.visibility = visibility;
    await profile.save();
    return profile;
  }

  // ------------------------------------------------------------ CV sections

  async addEntry(
    userId: string,
    section: CoachCvSection,
    entry: object,
  ): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const items = profile[section] as unknown as SubdocArray;
    if (items.length >= MAX_EMBEDDED_ARRAY_ITEMS) {
      throw new BadRequestException(
        `You've reached the maximum number of entries (${MAX_EMBEDDED_ARRAY_ITEMS}).`,
      );
    }
    (items as object[]).push(entry);
    await profile.save();
    return profile;
  }

  async updateEntry(
    userId: string,
    section: CoachCvSection,
    entryId: string,
    changes: object,
  ): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const items = profile[section] as unknown as SubdocArray;
    const entry = items.find((item) => item._id?.toString() === entryId);
    if (!entry) {
      throw new NotFoundException(SECTION_NOT_FOUND[section]);
    }
    Object.assign(entry, changes);
    await profile.save();
    return profile;
  }

  async removeEntry(
    userId: string,
    section: CoachCvSection,
    entryId: string,
  ): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const items = profile[section] as unknown as SubdocArray;
    if (!items.some((item) => item._id?.toString() === entryId)) {
      throw new NotFoundException(SECTION_NOT_FOUND[section]);
    }
    profile.set(
      section,
      items.filter((item) => item._id?.toString() !== entryId),
    );
    await profile.save();
    return profile;
  }

  // ------------------------------------------------------------------ media

  async addMedia(
    userId: string,
    file: Express.Multer.File,
    type: MediaType,
    caption?: string,
  ): Promise<CoachProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    validateMediaFile(type, file);
    const profile = await this.getOrCreateForUser(userId);
    if (profile.media.length >= MAX_EMBEDDED_ARRAY_ITEMS) {
      throw new BadRequestException(
        `You've reached the maximum number of media items (${MAX_EMBEDDED_ARRAY_ITEMS}).`,
      );
    }
    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/coaches/${userId}`,
      resourceTypeFor(type),
    );
    profile.media.push({
      type,
      publicId: upload.publicId,
      secureUrl: upload.secureUrl,
      caption,
    });
    try {
      await profile.save();
    } catch (error) {
      // Don't orphan the asset that already landed.
      await this.cloudinary.deleteAsset(upload.publicId, resourceTypeFor(type));
      throw error;
    }
    return profile;
  }

  async removeMedia(
    userId: string,
    mediaId: string,
  ): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const media = profile.media.find(
      (item) => item._id?.toString() === mediaId,
    );
    if (!media) {
      throw new NotFoundException('Media item not found.');
    }
    await this.cloudinary.deleteAsset(
      media.publicId,
      resourceTypeFor(media.type),
    );
    profile.set(
      'media',
      profile.media.filter((item) => item._id?.toString() !== mediaId),
    );
    await profile.save();
    return profile;
  }

  async setProfilePhoto(
    userId: string,
    file: Express.Multer.File,
  ): Promise<CoachProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    validateMediaFile(MediaType.PHOTO, file);
    const profile = await this.getOrCreateForUser(userId);
    const previous = profile.profilePhoto;

    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/coaches/${userId}`,
      'image',
    );
    profile.profilePhoto = {
      publicId: upload.publicId,
      secureUrl: upload.secureUrl,
    };
    try {
      await profile.save();
    } catch (error) {
      await this.cloudinary.deleteAsset(upload.publicId, 'image');
      throw error;
    }
    if (previous) {
      await this.cloudinary.deleteAsset(previous.publicId, 'image');
    }
    return profile;
  }

  async removeProfilePhoto(userId: string): Promise<CoachProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    if (!profile.profilePhoto) {
      throw new NotFoundException('No profile photo to remove.');
    }
    await this.cloudinary.deleteAsset(profile.profilePhoto.publicId, 'image');
    profile.profilePhoto = undefined;
    await profile.save();
    return profile;
  }

  // Admin delete-user cascade. A no-op if the coach never opened a profile.
  async deleteProfileAndMediaByUserId(userId: string): Promise<void> {
    const profile = await this.coachProfileModel.findOne({ userId });
    if (!profile) return;
    await Promise.all([
      ...profile.media.map((item) =>
        this.cloudinary.deleteAsset(item.publicId, resourceTypeFor(item.type)),
      ),
      ...(profile.profilePhoto
        ? [this.cloudinary.deleteAsset(profile.profilePhoto.publicId, 'image')]
        : []),
    ]);
    await this.coachProfileModel.deleteOne({ _id: profile._id });
  }
}
