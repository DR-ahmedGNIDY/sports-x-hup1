import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  ClubProfile,
  ClubProfileDocument,
} from '../clubs/schemas/club-profile.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { ALLOWED_IMAGE_MIME_TYPES } from '../common/upload.config';
import { assertFileContentMatchesMimeType } from '../common/file-signature';
import {
  PlayerProfile,
  PlayerProfileDocument,
} from '../players/schemas/player-profile.schema';
import { SportsService } from '../sports/sports.service';
import { User, UserRole } from '../users/schemas/user.schema';
import { VideosService } from '../videos/videos.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CreatePhotoPostDto } from './dto/create-photo-post.dto';
import { photoFeedItem, toCommentView, videoFeedItem } from './posts.mapper';
import { PhotoComment } from './schemas/photo-comment.schema';
import { PhotoLike } from './schemas/photo-like.schema';
import {
  PhotoPost,
  PhotoPostDocument,
  PostAuthorRole,
} from './schemas/photo-post.schema';

const DUPLICATE_KEY_ERROR_CODE = 11000;
const FEED_PAGE_SIZE = 12;
const COMMENTS_PAGE_SIZE = 20;

export interface FeedResult {
  items: Array<
    ReturnType<typeof videoFeedItem> | ReturnType<typeof photoFeedItem>
  >;
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class PostsService {
  constructor(
    @InjectModel(PhotoPost.name) private readonly photoModel: Model<PhotoPost>,
    @InjectModel(PhotoLike.name)
    private readonly photoLikeModel: Model<PhotoLike>,
    @InjectModel(PhotoComment.name)
    private readonly photoCommentModel: Model<PhotoComment>,
    @InjectModel(PlayerProfile.name)
    private readonly playerProfileModel: Model<PlayerProfile>,
    @InjectModel(ClubProfile.name)
    private readonly clubProfileModel: Model<ClubProfile>,
    @InjectModel(User.name) private readonly userModel: Model<User>,
    private readonly cloudinary: CloudinaryService,
    private readonly sportsService: SportsService,
    private readonly videosService: VideosService,
  ) {}

  private async findPhotoOrThrow(photoId: string): Promise<PhotoPostDocument> {
    if (!Types.ObjectId.isValid(photoId)) {
      throw new NotFoundException('Post not found.');
    }
    const photo = await this.photoModel.findById(photoId);
    if (!photo) {
      throw new NotFoundException('Post not found.');
    }
    return photo;
  }

  // A Player defaults to their own profile sport; a Club has no profile
  // sport to default from (see ClubProfile), so it must choose one — both
  // paths land on a value validated against the sports catalog.
  async createPost(
    userId: string,
    role: string,
    dto: CreatePhotoPostDto,
    file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `A post image must be one of: ${ALLOWED_IMAGE_MIME_TYPES.join(', ')}.`,
      );
    }
    assertFileContentMatchesMimeType(file, 'image');

    let sport: string;
    let authorRole: PostAuthorRole;
    if (role === UserRole.CLUB) {
      if (!dto.sport) {
        throw new BadRequestException('Choose a sport for this post.');
      }
      sport = dto.sport;
      authorRole = PostAuthorRole.CLUB;
    } else {
      const profile = await this.playerProfileModel.findOne({ userId });
      if (!profile) {
        throw new NotFoundException(
          'You must have a player profile before posting.',
        );
      }
      sport = dto.sport ?? profile.sport ?? '';
      if (!sport) {
        throw new BadRequestException(
          'Set your sport on your profile before posting, or choose one.',
        );
      }
      authorRole = PostAuthorRole.PLAYER;
    }
    await this.sportsService.assertSportExists(sport);

    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/posts/${userId}`,
      'image',
    );
    let photo: PhotoPostDocument;
    try {
      photo = await this.photoModel.create({
        authorUserId: userId,
        authorRole,
        sport,
        caption: dto.caption,
        publicId: upload.publicId,
        secureUrl: upload.secureUrl,
      });
    } catch (error) {
      // Same "don't orphan the Cloudinary asset" guard as VideosService.
      await this.cloudinary.deleteAsset(upload.publicId, 'image');
      throw error;
    }

    const author =
      authorRole === PostAuthorRole.CLUB
        ? await this.clubProfileModel.findOne({ userId })
        : await this.playerProfileModel.findOne({ userId });
    return photoFeedItem(photo, author);
  }

  // Merges Video (via VideosService) and Photo posts into one Home feed,
  // newest first, scoped to a single sport with no other filter. Fetches
  // the top `page * pageSize` rows from *each* source and merges/slices in
  // memory rather than a DB-level union: correct for any page depth, and
  // far simpler than a cross-collection $unionWith — the trade-off is
  // re-fetching earlier pages' rows on every request, which is a
  // non-issue at this app's scale (this isn't built for deep infinite
  // scroll over millions of posts).
  async homeFeed(sport: string, page = 1): Promise<FeedResult> {
    await this.sportsService.assertSportExists(sport);
    const upTo = page * FEED_PAGE_SIZE;

    const [videos, videoTotal, photos, photoTotal] = await Promise.all([
      this.videosService.findPublicForFeed(sport, upTo),
      this.videosService.countPublicForSport(sport),
      this.photoModel.find({ sport }).sort({ createdAt: -1 }).limit(upTo),
      this.photoModel.countDocuments({ sport }),
    ]);

    const playerIds = [...new Set(videos.map((v) => v.playerId.toString()))];
    const videoAuthorProfiles = playerIds.length
      ? await this.playerProfileModel.find({ _id: { $in: playerIds } })
      : [];
    const videoAuthorById = new Map(
      videoAuthorProfiles.map((p) => [p._id.toString(), p]),
    );

    const photoAuthorById = await this.resolvePostAuthors(photos);

    type Row = { createdAt: Date; item: FeedResult['items'][number] };
    const rows: Row[] = [
      ...videos.map((video) => ({
        createdAt: (video as unknown as { createdAt: Date }).createdAt,
        item: videoFeedItem(
          video,
          videoAuthorById.get(video.playerId.toString()) ?? null,
        ),
      })),
      ...photos.map((photo) => ({
        createdAt: (photo as unknown as { createdAt: Date }).createdAt,
        item: photoFeedItem(
          photo,
          photoAuthorById.get(photo._id.toString()) ?? null,
        ),
      })),
    ];
    rows.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    const pageItems = rows
      .slice((page - 1) * FEED_PAGE_SIZE, page * FEED_PAGE_SIZE)
      .map((row) => row.item);

    return {
      items: pageItems,
      page,
      pageSize: FEED_PAGE_SIZE,
      total: videoTotal + photoTotal,
    };
  }

  // Batched author resolution for a page of photos — one query against
  // PlayerProfile for every PLAYER author and one against ClubProfile for
  // every CLUB author, not one query per photo. Keyed by the photo's own
  // id (not the author id) since a single result map covers both roles.
  private async resolvePostAuthors(
    photos: PhotoPostDocument[],
  ): Promise<Map<string, PlayerProfileDocument | ClubProfileDocument | null>> {
    const result = new Map<
      string,
      PlayerProfileDocument | ClubProfileDocument | null
    >();
    if (photos.length === 0) return result;

    const playerUserIds = [
      ...new Set(
        photos
          .filter((p) => p.authorRole === PostAuthorRole.PLAYER)
          .map((p) => p.authorUserId.toString()),
      ),
    ];
    const clubUserIds = [
      ...new Set(
        photos
          .filter((p) => p.authorRole === PostAuthorRole.CLUB)
          .map((p) => p.authorUserId.toString()),
      ),
    ];

    const [players, clubs] = await Promise.all([
      playerUserIds.length
        ? this.playerProfileModel.find({ userId: { $in: playerUserIds } })
        : Promise.resolve([]),
      clubUserIds.length
        ? this.clubProfileModel.find({ userId: { $in: clubUserIds } })
        : Promise.resolve([]),
    ]);
    const playerByUserId = new Map(
      players.map((p) => [p.userId.toString(), p]),
    );
    const clubByUserId = new Map(clubs.map((c) => [c.userId.toString(), c]));

    for (const photo of photos) {
      const author =
        photo.authorRole === PostAuthorRole.CLUB
          ? (clubByUserId.get(photo.authorUserId.toString()) ?? null)
          : (playerByUserId.get(photo.authorUserId.toString()) ?? null);
      result.set(photo._id.toString(), author);
    }
    return result;
  }

  private assertViewable(): void {
    // Every photo post is public by design (no draft/private state in
    // V1 — see PhotoPost schema) so there's nothing to gate here; kept as
    // its own method so like/comment code below reads the same as
    // VideosService's, in case a visibility toggle is added later.
  }

  async like(userId: string, photoId: string) {
    const photo = await this.findPhotoOrThrow(photoId);
    this.assertViewable();
    try {
      await this.photoLikeModel.create({ photoId: photo._id, userId });
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new ConflictException('You have already liked this post.');
      }
      throw error;
    }
    const updated = await this.photoModel.findByIdAndUpdate(
      photo._id,
      { $inc: { likeCount: 1 } },
      { new: true },
    );
    return {
      likeCount: updated?.likeCount ?? photo.likeCount + 1,
      isLikedByMe: true,
    };
  }

  async unlike(userId: string, photoId: string) {
    const photo = await this.findPhotoOrThrow(photoId);
    this.assertViewable();
    const result = await this.photoLikeModel.deleteOne({
      photoId: photo._id,
      userId,
    });
    if (result.deletedCount === 0) {
      throw new NotFoundException('You have not liked this post.');
    }
    const updated = await this.photoModel.findByIdAndUpdate(
      photo._id,
      { $inc: { likeCount: photo.likeCount > 0 ? -1 : 0 } },
      { new: true },
    );
    return {
      likeCount: Math.max(0, updated?.likeCount ?? photo.likeCount - 1),
      isLikedByMe: false,
    };
  }

  // Mirrors VideosService.resolveDisplayNames — batched author-name
  // resolution for a page of comments (users, then players/clubs
  // partitioned by role) instead of one round-trip per unique author.
  private async resolveDisplayNames(
    userIds: string[],
  ): Promise<Map<string, { displayName: string; role: string }>> {
    const authorInfoById = new Map<
      string,
      { displayName: string; role: string }
    >();
    if (userIds.length === 0) return authorInfoById;

    const users = await this.userModel.find({ _id: { $in: userIds } });
    const userById = new Map(users.map((u) => [u._id.toString(), u]));

    const playerUserIds = users
      .filter((u) => u.role === 'PLAYER')
      .map((u) => u._id.toString());
    const clubUserIds = users
      .filter((u) => u.role === 'CLUB')
      .map((u) => u._id.toString());

    const [profiles, clubProfiles] = await Promise.all([
      playerUserIds.length
        ? this.playerProfileModel.find({ userId: { $in: playerUserIds } })
        : Promise.resolve([]),
      clubUserIds.length
        ? this.clubProfileModel.find({ userId: { $in: clubUserIds } })
        : Promise.resolve([]),
    ]);
    const profileByUserId = new Map(
      profiles.map((p) => [p.userId.toString(), p]),
    );
    const clubProfileByUserId = new Map(
      clubProfiles.map((p) => [p.userId.toString(), p]),
    );

    for (const id of userIds) {
      const user = userById.get(id);
      if (!user) {
        authorInfoById.set(id, { displayName: 'Unknown', role: 'UNKNOWN' });
        continue;
      }
      if (user.role === 'PLAYER') {
        const profile = profileByUserId.get(id);
        const name = [profile?.firstName, profile?.lastName]
          .filter(Boolean)
          .join(' ')
          .trim();
        authorInfoById.set(id, {
          displayName: name || user.email || user.phone || 'Player',
          role: user.role,
        });
        continue;
      }
      if (user.role === 'CLUB') {
        const profile = clubProfileByUserId.get(id);
        authorInfoById.set(id, {
          displayName: profile?.name || user.email || 'Club',
          role: user.role,
        });
        continue;
      }
      authorInfoById.set(id, { displayName: 'Admin', role: user.role });
    }
    return authorInfoById;
  }

  async listComments(userId: string, photoId: string, page = 1) {
    const photo = await this.findPhotoOrThrow(photoId);
    this.assertViewable();
    const filter = { photoId: photo._id };
    const [comments, total] = await Promise.all([
      this.photoCommentModel
        .find(filter)
        .sort({ createdAt: 1 })
        .skip((page - 1) * COMMENTS_PAGE_SIZE)
        .limit(COMMENTS_PAGE_SIZE),
      this.photoCommentModel.countDocuments(filter),
    ]);

    const uniqueAuthorIds = [
      ...new Set(comments.map((c) => c.userId.toString())),
    ];
    const authorInfoById = await this.resolveDisplayNames(uniqueAuthorIds);

    return {
      items: comments.map((comment) => {
        const info = authorInfoById.get(comment.userId.toString()) ?? {
          displayName: 'Unknown',
          role: 'UNKNOWN',
        };
        return toCommentView(comment, info.displayName, info.role, userId);
      }),
      page,
      pageSize: COMMENTS_PAGE_SIZE,
      total,
    };
  }

  async addComment(userId: string, photoId: string, dto: CreateCommentDto) {
    const photo = await this.findPhotoOrThrow(photoId);
    this.assertViewable();
    const comment = await this.photoCommentModel.create({
      photoId: photo._id,
      userId,
      text: dto.text,
    });
    await this.photoModel.updateOne(
      { _id: photo._id },
      { $inc: { commentCount: 1 } },
    );
    const authorInfoById = await this.resolveDisplayNames([userId]);
    const info = authorInfoById.get(userId) ?? {
      displayName: 'Unknown',
      role: 'UNKNOWN',
    };
    return toCommentView(comment, info.displayName, info.role, userId);
  }

  async deleteComment(
    userId: string,
    role: string,
    photoId: string,
    commentId: string,
  ): Promise<void> {
    const photo = await this.findPhotoOrThrow(photoId);
    this.assertViewable();
    if (!Types.ObjectId.isValid(commentId)) {
      throw new NotFoundException('Comment not found.');
    }
    const comment = await this.photoCommentModel.findOne({
      _id: commentId,
      photoId: photo._id,
    });
    if (!comment) {
      throw new NotFoundException('Comment not found.');
    }
    if (comment.userId.toString() !== userId && role !== 'ADMIN') {
      throw new ForbiddenException('You do not have access to this comment.');
    }
    await this.photoCommentModel.deleteOne({ _id: comment._id });
    await this.photoModel.updateOne(
      { _id: photo._id, commentCount: { $gt: 0 } },
      { $inc: { commentCount: -1 } },
    );
  }
}
