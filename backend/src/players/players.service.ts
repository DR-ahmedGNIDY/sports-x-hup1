import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  CloudinaryResourceType,
  CloudinaryService,
} from '../cloudinary/cloudinary.service';
import {
  ALLOWED_IMAGE_MIME_TYPES,
  ALLOWED_VIDEO_MIME_TYPES,
  IMAGE_SIZE_LIMIT_BYTES,
  VIDEO_SIZE_LIMIT_BYTES,
} from '../common/upload.config';
import { assertFileContentMatchesMimeType } from '../common/file-signature';
import {
  PublicCodePrefix,
  PublicCodesService,
} from '../public-codes/public-codes.service';
import { SavedPlayer } from '../saved-players/schemas/saved-player.schema';
import { VideosService } from '../videos/videos.service';
import {
  CreateAchievementDto,
  UpdateAchievementDto,
} from './dto/achievement.dto';
import {
  CreateSocialLinkDto,
  UpdateSocialLinkDto,
} from './dto/social-link.dto';
import { SearchPlayersDto } from './dto/search-players.dto';
import { UpdatePlayerProfileDto } from './dto/update-player-profile.dto';
import { UpdateVisibilityDto } from './dto/update-visibility.dto';
import {
  MediaType,
  PlayerProfile,
  PlayerProfileDocument,
  ProfileVisibility,
} from './schemas/player-profile.schema';

function resourceTypeFor(type: MediaType): CloudinaryResourceType {
  return type === MediaType.VIDEO ? 'video' : 'image';
}

// The upload interceptor's fileFilter (upload.config.ts) only rejects files
// that are neither an allowed image nor an allowed video type — it can't
// know which one the caller *declared* via the `type` field, since that's a
// separate multipart field, not the file part. This closes that gap: a
// PHOTO upload must actually be an image (and within the tighter photo size
// cap), a VIDEO upload must actually be a video.
function validateMediaFile(type: MediaType, file: Express.Multer.File): void {
  if (type === MediaType.PHOTO) {
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `A PHOTO upload must be one of: ${ALLOWED_IMAGE_MIME_TYPES.join(', ')}.`,
      );
    }
    if (file.size > IMAGE_SIZE_LIMIT_BYTES) {
      throw new BadRequestException(
        `Photo exceeds the ${IMAGE_SIZE_LIMIT_BYTES / (1024 * 1024)}MB limit.`,
      );
    }
    assertFileContentMatchesMimeType(file, 'image');
    return;
  }
  if (!ALLOWED_VIDEO_MIME_TYPES.includes(file.mimetype)) {
    throw new BadRequestException(
      `A VIDEO upload must be one of: ${ALLOWED_VIDEO_MIME_TYPES.join(', ')}.`,
    );
  }
  if (file.size > VIDEO_SIZE_LIMIT_BYTES) {
    throw new BadRequestException(
      `Video exceeds the ${VIDEO_SIZE_LIMIT_BYTES / (1024 * 1024)}MB limit.`,
    );
  }
  assertFileContentMatchesMimeType(file, 'video');
}

const SEARCH_PAGE_SIZE = 20;
const ADMIN_LIST_PAGE_SIZE = 20;
const CLUB_ROSTER_PAGE_SIZE = 20;

// Escapes regex metacharacters in free-text search input before it's used
// inside a MongoDB $regex filter — without this, a search string like
// "a.*" or "(" would be interpreted as regex syntax instead of literal
// text (and unbalanced groups throw at query time).
function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Caps unbounded growth of a profile's embedded arrays — each item lives
// inside the PlayerProfile document itself (not a separate collection), so
// without a ceiling a single profile could be grown without limit.
const MAX_EMBEDDED_ARRAY_ITEMS = 30;

// A minimum date of birth (i.e. maxAge) excludes anyone born before it;
// a maximum date of birth (i.e. minAge) excludes anyone born after it.
function dateOfBirthAtLeastAge(age: number): Date {
  const date = new Date();
  date.setFullYear(date.getFullYear() - age);
  return date;
}

export interface PlayerSearchResult {
  items: PlayerProfileDocument[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class PlayersService {
  constructor(
    @InjectModel(PlayerProfile.name)
    private readonly playerProfileModel: Model<PlayerProfile>,
    @InjectModel(SavedPlayer.name)
    private readonly savedPlayerModel: Model<SavedPlayer>,
    private readonly cloudinary: CloudinaryService,
    private readonly videosService: VideosService,
    private readonly publicCodes: PublicCodesService,
  ) {}

  // Atomic upsert, not findOne-then-create: the Dashboard and Edit Profile
  // pages both load on mount and each depend on a profile existing, so for
  // a brand-new player two requests (e.g. GET /players/me and GET
  // /players/me/stats) can land concurrently. A separate findOne + create
  // lets both see "not found" and both try to insert, and the loser dies
  // on the unique userId index instead of just returning the row the
  // winner created.
  async getOrCreateForUser(userId: string): Promise<PlayerProfileDocument> {
    const profile = await this.playerProfileModel.findOneAndUpdate(
      { userId },
      { $setOnInsert: { userId } },
      { new: true, upsert: true },
    );
    return this.ensurePublicCode(profile);
  }

  // Assigns the player's shareable code on first need — same contract as
  // ClubsService.ensurePublicCode: allocated once, never rewritten, and the
  // conditional update means a race re-reads the winner's code instead of
  // clobbering it.
  async ensurePublicCode(
    profile: PlayerProfileDocument,
  ): Promise<PlayerProfileDocument> {
    if (profile.publicCode) return profile;

    const publicCode = await this.publicCodes.allocate(PublicCodePrefix.PLAYER);
    const updated = await this.playerProfileModel.findOneAndUpdate(
      { _id: profile._id, publicCode: { $in: [null, undefined] } },
      { $set: { publicCode } },
      { new: true },
    );
    return updated ?? (await this.playerProfileModel.findById(profile._id))!;
  }

  // Indexed equality lookup on the unique `publicCode` field. Applies the
  // same PUBLIC-only rule as findPublicByIdOrThrow — a code must not become
  // a way around a player's visibility setting — and answers 404 for a
  // malformed code without a database round-trip.
  async findPublicByCodeOrThrow(code: string): Promise<PlayerProfileDocument> {
    const normalized = PublicCodesService.normalizeFor(
      code,
      PublicCodePrefix.PLAYER,
    );
    if (!normalized) {
      throw new NotFoundException('Player not found.');
    }
    const profile = await this.playerProfileModel.findOne({
      publicCode: normalized,
    });
    if (!profile || profile.visibility !== ProfileVisibility.PUBLIC) {
      throw new NotFoundException('Player not found.');
    }
    return profile;
  }

  // Read-only counterpart to getOrCreateForUser, for callers where a missing
  // profile means "no such player" rather than "create one on demand".
  findByUserId(userId: string): Promise<PlayerProfileDocument | null> {
    return this.playerProfileModel.findOne({ userId });
  }

  async findPublicByIdOrThrow(id: string): Promise<PlayerProfileDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Player not found.');
    }
    const profile = await this.playerProfileModel.findById(id);
    if (!profile || profile.visibility !== ProfileVisibility.PUBLIC) {
      throw new NotFoundException('Player not found.');
    }
    return profile;
  }

  async search(dto: SearchPlayersDto): Promise<PlayerSearchResult> {
    const filter: Record<string, unknown> = {
      visibility: ProfileVisibility.PUBLIC,
    };
    if (dto.search && dto.search.trim()) {
      // Name only — this is a public, unauthenticated endpoint, so phone
      // (private contact data) is never part of the match here, unlike
      // the Club's own roster search in findManyByUserIdsFiltered.
      //
      // Performance note (release-audit P1): an unanchored, case-
      // insensitive $regex like this cannot use a standard B-tree index
      // regardless of what's indexed on firstName/lastName — MongoDB has
      // to scan every document the other filter fields (visibility here)
      // leave as candidates. Fine at the collection sizes expected for
      // this MVP (visibility: PUBLIC already narrows the scan, and the
      // 20-item page size bounds the response either way). If this ever
      // needs to scale past a few thousand PUBLIC profiles, the fix is a
      // MongoDB text index + $text query — deliberately not done here,
      // since $text tokenizes on word boundaries and would change
      // "contains" matching (e.g. "med" no longer matching "Ahmed")
      // rather than just speeding up the current behavior.
      const regex = { $regex: escapeRegex(dto.search.trim()), $options: 'i' };
      filter.$or = [{ firstName: regex }, { lastName: regex }];
    }
    if (dto.country) filter.country = dto.country;
    if (dto.position) filter.position = dto.position;
    if (dto.sport) filter.sport = dto.sport;
    if (dto.preferredFoot) filter.preferredFoot = dto.preferredFoot;
    if (dto.weight !== undefined) filter.weight = dto.weight;

    if (dto.minHeight !== undefined || dto.maxHeight !== undefined) {
      filter.height = {
        ...(dto.minHeight !== undefined && { $gte: dto.minHeight }),
        ...(dto.maxHeight !== undefined && { $lte: dto.maxHeight }),
      };
    }

    // minAge=20 → born on/before (today - 20y); maxAge=25 → born on/after (today - 25y).
    if (dto.minAge !== undefined || dto.maxAge !== undefined) {
      filter.dateOfBirth = {
        ...(dto.minAge !== undefined && {
          $lte: dateOfBirthAtLeastAge(dto.minAge),
        }),
        ...(dto.maxAge !== undefined && {
          $gte: dateOfBirthAtLeastAge(dto.maxAge),
        }),
      };
    }

    const page = dto.page ?? 1;
    const [items, total] = await Promise.all([
      this.playerProfileModel
        .find(filter)
        .skip((page - 1) * SEARCH_PAGE_SIZE)
        .limit(SEARCH_PAGE_SIZE),
      this.playerProfileModel.countDocuments(filter),
    ]);

    return { items, page, pageSize: SEARCH_PAGE_SIZE, total };
  }

  findManyPublicByIds(ids: string[]): Promise<PlayerProfileDocument[]> {
    return this.playerProfileModel.find({
      _id: { $in: ids },
      visibility: ProfileVisibility.PUBLIC,
    });
  }

  // A club's *public* roster page — the members list on a public club
  // profile. PUBLIC-only and counted on the same filter, so a private
  // member is absent from both the page and the total: showing "5 of 8"
  // would disclose the existence of the three this endpoint may not show.
  // Belonging to a club is not a way around a player's visibility setting,
  // the same rule findPublicByCodeOrThrow enforces for codes.
  async findManyPublicByUserIds(
    userIds: string[],
    page = 1,
  ): Promise<PlayerSearchResult> {
    const filter = {
      userId: { $in: userIds },
      visibility: ProfileVisibility.PUBLIC,
    };
    const [items, total] = await Promise.all([
      this.playerProfileModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * SEARCH_PAGE_SIZE)
        .limit(SEARCH_PAGE_SIZE),
      this.playerProfileModel.countDocuments(filter),
    ]);
    return { items, page, pageSize: SEARCH_PAGE_SIZE, total };
  }

  // Unlike findManyPublicByIds, not restricted to PUBLIC — used by a club
  // to list the players it manages regardless of their current visibility.
  findManyByUserIds(userIds: string[]): Promise<PlayerProfileDocument[]> {
    return this.playerProfileModel.find({ userId: { $in: userIds } });
  }

  // Same audience as findManyByUserIds (a club's own roster) but paginated
  // and optionally narrowed by name/phone search and sport/position
  // filters — backs GET /club-players. [userIds] bounds every query to
  // the calling club's own roster (via the unique index already on
  // `userId`), so this never scans the full players collection the way
  // the public search/admin-list endpoints intentionally can.
  async findManyByUserIdsFiltered(
    userIds: string[],
    {
      search,
      sport,
      position,
      page = 1,
    }: { search?: string; sport?: string; position?: string; page?: number },
  ): Promise<PlayerSearchResult> {
    const filter: Record<string, unknown> = { userId: { $in: userIds } };
    if (sport) filter.sport = sport;
    if (position) filter.position = position;
    if (search && search.trim()) {
      // Same unindexed-regex trade-off as search() above — see that
      // function's comment. Lower-risk here since this is always scoped
      // to one club's own roster (`userId: $in userIds`), which is small
      // by construction, not the whole players collection.
      const regex = { $regex: escapeRegex(search.trim()), $options: 'i' };
      filter.$or = [
        { firstName: regex },
        { lastName: regex },
        { 'contact.phone': regex },
      ];
    }

    const [items, total] = await Promise.all([
      this.playerProfileModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * CLUB_ROSTER_PAGE_SIZE)
        .limit(CLUB_ROSTER_PAGE_SIZE),
      this.playerProfileModel.countDocuments(filter),
    ]);
    return { items, page, pageSize: CLUB_ROSTER_PAGE_SIZE, total };
  }

  // Admin (Phase 4) — every profile regardless of visibility, paginated so
  // this can't attempt to load the full collection at launch scale.
  async findAllForAdmin(page = 1): Promise<PlayerSearchResult> {
    const [items, total] = await Promise.all([
      this.playerProfileModel
        .find()
        .sort({ createdAt: -1 })
        .skip((page - 1) * ADMIN_LIST_PAGE_SIZE)
        .limit(ADMIN_LIST_PAGE_SIZE),
      this.playerProfileModel.countDocuments(),
    ]);
    return { items, page, pageSize: ADMIN_LIST_PAGE_SIZE, total };
  }

  async deleteProfileAndMedia(id: string): Promise<void> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Player not found.');
    }
    const profile = await this.playerProfileModel.findById(id);
    if (!profile) {
      throw new NotFoundException('Player not found.');
    }
    await Promise.all(
      profile.media.map((item) =>
        this.cloudinary.deleteAsset(item.publicId, resourceTypeFor(item.type)),
      ),
    );
    // Cascade: without this, a deleted player's videos keep pointing at a
    // playerId that no longer resolves — surfacing as `author: null`
    // entries in the Community feed, with their Cloudinary assets and
    // likes/comments never cleaned up.
    await this.videosService.deleteAllForPlayer(id);
    await this.playerProfileModel.deleteOne({ _id: id });
  }

  // Same cascade as deleteProfileAndMedia, looked up by the owning user's
  // id instead of the profile id — used by UsersService.deleteById (admin
  // delete-user) so it doesn't need direct access to the PlayerProfile
  // model. A no-op if the user never created a player profile.
  async deleteProfileAndMediaByUserId(userId: string): Promise<void> {
    const profile = await this.playerProfileModel.findOne({ userId });
    if (!profile) {
      return;
    }
    await this.deleteProfileAndMedia(profile._id.toString());
  }

  async updateProfile(
    userId: string,
    dto: UpdatePlayerProfileDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    // `contact` is a nested subdocument — Object.assign-ing it directly
    // would replace the whole object, silently wiping any previously saved
    // field the caller didn't include in this partial update (e.g. sending
    // only `{ contact: { phone } }` would erase `email`/`whatsapp`). Merge
    // it field-by-field instead; every other DTO field is a scalar, so a
    // shallow assign is correct for the rest.
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
    dto: UpdateVisibilityDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    profile.visibility = dto.visibility;
    await profile.save();
    return profile;
  }

  // Photo-only: video uploads moved to the dedicated `videos` module.
  // Album only — the profile photo has its own field/method (setProfilePhoto
  // below) and is never stored in this array.
  async addMedia(
    userId: string,
    file: Express.Multer.File,
  ): Promise<PlayerProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    validateMediaFile(MediaType.PHOTO, file);
    const profile = await this.getOrCreateForUser(userId);
    if (profile.media.length >= MAX_EMBEDDED_ARRAY_ITEMS) {
      throw new BadRequestException(
        `You've reached the maximum number of media items (${MAX_EMBEDDED_ARRAY_ITEMS}).`,
      );
    }
    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/players/${userId}`,
      resourceTypeFor(MediaType.PHOTO),
    );

    profile.media.push({
      type: MediaType.PHOTO,
      publicId: upload.publicId,
      secureUrl: upload.secureUrl,
      isProfilePhoto: false,
    });
    try {
      await profile.save();
    } catch (error) {
      // The Cloudinary asset already landed — without this the DB write
      // failing would leave it orphaned (never referenced, never cleaned
      // up) while the caller gets a raw 500.
      await this.cloudinary.deleteAsset(
        upload.publicId,
        resourceTypeFor(MediaType.PHOTO),
      );
      throw error;
    }
    return profile;
  }

  // Separate from addMedia/the `media` album entirely — stores into the
  // dedicated `profilePhoto` field, replacing (and deleting) whatever was
  // there before.
  async setProfilePhoto(
    userId: string,
    file: Express.Multer.File,
  ): Promise<PlayerProfileDocument> {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    validateMediaFile(MediaType.PHOTO, file);
    const profile = await this.getOrCreateForUser(userId);
    const previous = profile.profilePhoto;

    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/players/${userId}`,
      resourceTypeFor(MediaType.PHOTO),
    );

    profile.profilePhoto = {
      publicId: upload.publicId,
      secureUrl: upload.secureUrl,
    };
    try {
      await profile.save();
    } catch (error) {
      await this.cloudinary.deleteAsset(
        upload.publicId,
        resourceTypeFor(MediaType.PHOTO),
      );
      throw error;
    }
    if (previous) {
      await this.cloudinary.deleteAsset(
        previous.publicId,
        resourceTypeFor(MediaType.PHOTO),
      );
    }
    return profile;
  }

  async removeProfilePhoto(userId: string): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    if (!profile.profilePhoto) {
      throw new NotFoundException('No profile photo to remove.');
    }
    await this.cloudinary.deleteAsset(
      profile.profilePhoto.publicId,
      resourceTypeFor(MediaType.PHOTO),
    );
    profile.profilePhoto = undefined;
    await profile.save();
    return profile;
  }

  async removeMedia(
    userId: string,
    mediaId: string,
  ): Promise<PlayerProfileDocument> {
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
    profile.media = profile.media.filter(
      (item) => item._id?.toString() !== mediaId,
    ) as typeof profile.media;
    await profile.save();
    return profile;
  }

  async addAchievement(
    userId: string,
    dto: CreateAchievementDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    if (profile.achievements.length >= MAX_EMBEDDED_ARRAY_ITEMS) {
      throw new BadRequestException(
        `You've reached the maximum number of achievements (${MAX_EMBEDDED_ARRAY_ITEMS}).`,
      );
    }
    profile.achievements.push(dto);
    await profile.save();
    return profile;
  }

  async updateAchievement(
    userId: string,
    achievementId: string,
    dto: UpdateAchievementDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const achievement = profile.achievements.find(
      (item) => item._id?.toString() === achievementId,
    );
    if (!achievement) {
      throw new NotFoundException('Achievement not found.');
    }
    Object.assign(achievement, dto);
    await profile.save();
    return profile;
  }

  async removeAchievement(
    userId: string,
    achievementId: string,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const exists = profile.achievements.some(
      (item) => item._id?.toString() === achievementId,
    );
    if (!exists) {
      throw new NotFoundException('Achievement not found.');
    }
    profile.achievements = profile.achievements.filter(
      (item) => item._id?.toString() !== achievementId,
    ) as typeof profile.achievements;
    await profile.save();
    return profile;
  }

  async addSocialLink(
    userId: string,
    dto: CreateSocialLinkDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    if (profile.socialLinks.length >= MAX_EMBEDDED_ARRAY_ITEMS) {
      throw new BadRequestException(
        `You've reached the maximum number of social links (${MAX_EMBEDDED_ARRAY_ITEMS}).`,
      );
    }
    profile.socialLinks.push(dto);
    await profile.save();
    return profile;
  }

  async updateSocialLink(
    userId: string,
    linkId: string,
    dto: UpdateSocialLinkDto,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const link = profile.socialLinks.find(
      (item) => item._id?.toString() === linkId,
    );
    if (!link) {
      throw new NotFoundException('Social link not found.');
    }
    Object.assign(link, dto);
    await profile.save();
    return profile;
  }

  async removeSocialLink(
    userId: string,
    linkId: string,
  ): Promise<PlayerProfileDocument> {
    const profile = await this.getOrCreateForUser(userId);
    const exists = profile.socialLinks.some(
      (item) => item._id?.toString() === linkId,
    );
    if (!exists) {
      throw new NotFoundException('Social link not found.');
    }
    profile.socialLinks = profile.socialLinks.filter(
      (item) => item._id?.toString() !== linkId,
    ) as typeof profile.socialLinks;
    await profile.save();
    return profile;
  }

  async getStatsForUser(userId: string): Promise<{
    profile: PlayerProfileDocument;
    savedByClubsCount: number;
  }> {
    const profile = await this.getOrCreateForUser(userId);
    const savedByClubsCount = await this.savedPlayerModel.countDocuments({
      playerId: profile._id,
    });
    return { profile, savedByClubsCount };
  }
}
