import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { UpdateClubProfileDto } from './dto/update-club-profile.dto';
import {
  ClubProfile,
  ClubProfileDocument,
} from './schemas/club-profile.schema';

const CLUB_LIST_PAGE_SIZE = 20;

export interface ClubPaginatedResult {
  items: ClubProfileDocument[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class ClubsService {
  constructor(
    @InjectModel(ClubProfile.name)
    private readonly clubProfileModel: Model<ClubProfile>,
    private readonly cloudinary: CloudinaryService,
  ) {}

  async getOrCreateForUser(userId: string): Promise<ClubProfileDocument> {
    let profile = await this.clubProfileModel.findOne({ userId });
    if (!profile) {
      profile = await this.clubProfileModel.create({ userId });
    }
    return profile;
  }

  // Public (Phase 5) — Public Clubs listing. Club profiles have no private
  // fields to gate (see clubs.mapper.ts), so unlike player search this
  // doesn't need a visibility filter; it's the same "all clubs" shape the
  // Admin list already uses, just reachable without auth and without the
  // Admin-only concerns.
  async findAllPublic(
    page = 1,
    country?: string,
  ): Promise<ClubPaginatedResult> {
    const filter: Record<string, unknown> = {};
    if (country) filter.country = country;
    const [items, total] = await Promise.all([
      this.clubProfileModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * CLUB_LIST_PAGE_SIZE)
        .limit(CLUB_LIST_PAGE_SIZE),
      this.clubProfileModel.countDocuments(filter),
    ]);
    return { items, page, pageSize: CLUB_LIST_PAGE_SIZE, total };
  }

  async findByIdOrThrow(id: string): Promise<ClubProfileDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Club not found.');
    }
    const profile = await this.clubProfileModel.findById(id);
    if (!profile) {
      throw new NotFoundException('Club not found.');
    }
    return profile;
  }

  async updateProfile(
    userId: string,
    dto: UpdateClubProfileDto,
  ): Promise<ClubProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    Object.assign(profile, dto);
    await profile.save();
    return profile;
  }

  async uploadLogo(
    userId: string,
    file: Express.Multer.File,
  ): Promise<ClubProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    const profile = await this.getOrCreateForUser(userId);
    if (profile.logo) {
      await this.cloudinary.deleteAsset(profile.logo.publicId, 'image');
    }
    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/clubs/${userId}`,
      'image',
    );
    profile.logo = { publicId: upload.publicId, secureUrl: upload.secureUrl };
    await profile.save();
    return profile;
  }

  // Admin (Phase 4) — paginated so this can't attempt to load the full
  // collection at launch scale.
  async findAllForAdmin(page = 1): Promise<ClubPaginatedResult> {
    const [items, total] = await Promise.all([
      this.clubProfileModel
        .find()
        .sort({ createdAt: -1 })
        .skip((page - 1) * CLUB_LIST_PAGE_SIZE)
        .limit(CLUB_LIST_PAGE_SIZE),
      this.clubProfileModel.countDocuments(),
    ]);
    return { items, page, pageSize: CLUB_LIST_PAGE_SIZE, total };
  }

  async deleteProfileAndLogo(id: string): Promise<void> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Club not found.');
    }
    const profile = await this.clubProfileModel.findById(id);
    if (!profile) {
      throw new NotFoundException('Club not found.');
    }
    if (profile.logo) {
      await this.cloudinary.deleteAsset(profile.logo.publicId, 'image');
    }
    await this.clubProfileModel.deleteOne({ _id: id });
  }

  // Same cleanup as deleteProfileAndLogo, looked up by the owning user's
  // id instead of the profile id — used by UsersService.deleteById (admin
  // delete-user) so it doesn't need direct access to the ClubProfile
  // model. A no-op if the user never created a club profile.
  async deleteProfileAndLogoByUserId(userId: string): Promise<void> {
    const profile = await this.clubProfileModel.findOne({ userId });
    if (!profile) {
      return;
    }
    await this.deleteProfileAndLogo(profile._id.toString());
  }
}
