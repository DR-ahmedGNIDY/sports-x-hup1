import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { ALLOWED_IMAGE_MIME_TYPES } from '../common/upload.config';
import { assertFileContentMatchesMimeType } from '../common/file-signature';
import {
  PublicCodePrefix,
  PublicCodesService,
} from '../public-codes/public-codes.service';
import { UpdateClubProfileDto } from './dto/update-club-profile.dto';
import {
  ClubProfile,
  ClubProfileDocument,
} from './schemas/club-profile.schema';

const CLUB_LIST_PAGE_SIZE = 20;

// Everything a user types reaches the query as literal text, never as
// pattern syntax. Duplicated from PlayersService rather than shared: one
// four-line function is a smaller thing to have twice than a utils module
// two features reach into for it.
function escapeClubRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

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
    private readonly publicCodes: PublicCodesService,
  ) {}

  async getOrCreateForUser(userId: string): Promise<ClubProfileDocument> {
    let profile = await this.clubProfileModel.findOne({ userId });
    if (!profile) {
      profile = await this.clubProfileModel.create({ userId });
    }
    return this.ensurePublicCode(profile);
  }

  // Assigns the club's shareable code the first time it's needed, so
  // profiles created before this feature existed pick one up on their next
  // load without a required migration (the backfill script just does it in
  // bulk instead of waiting). Never rewrites an existing code — a code is a
  // published identity, not a mutable field.
  //
  // The write is conditional on `publicCode` still being absent, so if two
  // requests race here the loser's update matches nothing and it re-reads
  // the winner's code rather than overwriting it. A burnt counter value is
  // the only cost; codes are identifiers, not a contiguous count.
  async ensurePublicCode(
    profile: ClubProfileDocument,
  ): Promise<ClubProfileDocument> {
    if (profile.publicCode) return profile;

    const publicCode = await this.publicCodes.allocate(PublicCodePrefix.CLUB);
    const updated = await this.clubProfileModel.findOneAndUpdate(
      { _id: profile._id, publicCode: { $in: [null, undefined] } },
      { $set: { publicCode } },
      { new: true },
    );
    return updated ?? (await this.clubProfileModel.findById(profile._id))!;
  }

  // Indexed equality lookup on the unique `publicCode` field — never a
  // collection scan. Returns 404 for a malformed code without touching the
  // database, so a bad string costs nothing.
  async findByPublicCodeOrThrow(code: string): Promise<ClubProfileDocument> {
    const normalized = PublicCodesService.normalizeFor(
      code,
      PublicCodePrefix.CLUB,
    );
    if (!normalized) {
      throw new NotFoundException('Club not found.');
    }
    const profile = await this.clubProfileModel.findOne({
      publicCode: normalized,
    });
    if (!profile) {
      throw new NotFoundException('Club not found.');
    }
    return profile;
  }

  // Read-only counterpart to getOrCreateForUser — used where a missing club
  // profile means "no such club" (e.g. an invitation's counterpart) rather
  // than "create one on demand".
  findByUserId(userId: string): Promise<ClubProfileDocument | null> {
    return this.clubProfileModel.findOne({ userId });
  }

  // Batch counterpart lookup for a page of invitations, so rendering N rows
  // costs one query rather than N.
  findManyByUserIds(userIds: string[]): Promise<ClubProfileDocument[]> {
    return this.clubProfileModel.find({ userId: { $in: userIds } });
  }

  // Public (Phase 5) — Public Clubs listing. Club profiles have no private
  // fields to gate (see clubs.mapper.ts), so unlike player search this
  // doesn't need a visibility filter; it's the same "all clubs" shape the
  // Admin list already uses, just reachable without auth and without the
  // Admin-only concerns.
  async findAllPublic(
    page = 1,
    country?: string,
    search?: string,
  ): Promise<ClubPaginatedResult> {
    const filter: Record<string, unknown> = {};
    if (country) filter.country = country;
    if (search && search.trim()) {
      // Same unindexed-regex trade-off the player search documents, and the
      // same escaping: without it a name containing "(" or "a.*" would be
      // read as a pattern rather than as text, and an unbalanced group
      // throws at query time. Clubs are a far smaller collection than
      // players, so the scan costs less here than it does there.
      filter.name = { $regex: escapeClubRegex(search.trim()), $options: 'i' };
    }
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
    // Defensive re-check, matching the pattern already used for player
    // media/video/post-image uploads: `imageUploadOptions`' fileFilter
    // already rejects non-image mimetypes, but don't trust the interceptor
    // was the only gate, and confirm the content is actually an image
    // (CWE-434) — this endpoint previously had no service-layer re-check.
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `A club logo must be one of: ${ALLOWED_IMAGE_MIME_TYPES.join(', ')}.`,
      );
    }
    assertFileContentMatchesMimeType(file, 'image');
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
