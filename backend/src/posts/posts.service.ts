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
import {
  CoachProfile,
  CoachProfileDocument,
} from '../coaches/schemas/coach-profile.schema';
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

type PostAuthorProfile =
  PlayerProfileDocument | ClubProfileDocument | CoachProfileDocument;

const DUPLICATE_KEY_ERROR_CODE = 11000;
const FEED_PAGE_SIZE = 12;
const COMMENTS_PAGE_SIZE = 20;

// The Home feed carries two kinds of item (see posts.mapper) and both are
// moderatable, so every moderation entry point is addressed by kind + id.
export type FeedItemKind = 'PHOTO' | 'VIDEO';

// Who is reading (or acting on) the feed. Drives two things the response
// shape depends on: whether hidden posts are visible at all, and which
// per-item actions the card should offer.
export interface FeedViewer {
  userId?: string;
  role?: string;
  isModerator?: boolean;
}

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
    @InjectModel(CoachProfile.name)
    private readonly coachProfileModel: Model<CoachProfile>,
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
    } else if (role === UserRole.COACH) {
      const profile = await this.coachProfileModel.findOne({ userId });
      sport = dto.sport ?? profile?.sport ?? '';
      if (!sport) {
        throw new BadRequestException(
          'Set your sport on your profile before posting, or choose one.',
        );
      }
      authorRole = PostAuthorRole.COACH;
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
        : authorRole === PostAuthorRole.COACH
          ? await this.coachProfileModel.findOne({ userId })
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
  async homeFeed(
    sport: string,
    page = 1,
    viewer: FeedViewer = {},
  ): Promise<FeedResult> {
    await this.sportsService.assertSportExists(sport);
    const upTo = page * FEED_PAGE_SIZE;

    // A moderator keeps seeing hidden posts (flagged as such by the mapper)
    // so they can review and unhide them; everyone else never sees them.
    const canModerate =
      viewer.isModerator === true || viewer.role === UserRole.ADMIN;
    const photoFilter = canModerate ? { sport } : { sport, isHidden: false };

    const [videos, videoTotal, photos, photoTotal] = await Promise.all([
      this.videosService.findPublicForFeed(sport, upTo),
      this.videosService.countPublicForSport(sport),
      this.photoModel.find(photoFilter).sort({ createdAt: -1 }).limit(upTo),
      this.photoModel.countDocuments(photoFilter),
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
          {
            isMine: video.userId.toString() === viewer.userId,
            canModerate,
          },
        ),
      })),
      ...photos.map((photo) => ({
        createdAt: (photo as unknown as { createdAt: Date }).createdAt,
        item: photoFeedItem(
          photo,
          photoAuthorById.get(photo._id.toString()) ?? null,
          {
            isMine: photo.authorUserId.toString() === viewer.userId,
            canModerate,
          },
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
  ): Promise<Map<string, PostAuthorProfile | null>> {
    const result = new Map<string, PostAuthorProfile | null>();
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

    const coachUserIds = [
      ...new Set(
        photos
          .filter((p) => p.authorRole === PostAuthorRole.COACH)
          .map((p) => p.authorUserId.toString()),
      ),
    ];

    const [players, clubs, coaches] = await Promise.all([
      playerUserIds.length
        ? this.playerProfileModel.find({ userId: { $in: playerUserIds } })
        : Promise.resolve([]),
      clubUserIds.length
        ? this.clubProfileModel.find({ userId: { $in: clubUserIds } })
        : Promise.resolve([]),
      coachUserIds.length
        ? this.coachProfileModel.find({ userId: { $in: coachUserIds } })
        : Promise.resolve([]),
    ]);
    const coachByUserId = new Map(coaches.map((c) => [c.userId.toString(), c]));
    const playerByUserId = new Map(
      players.map((p) => [p.userId.toString(), p]),
    );
    const clubByUserId = new Map(clubs.map((c) => [c.userId.toString(), c]));

    for (const photo of photos) {
      const authorId = photo.authorUserId.toString();
      const author =
        photo.authorRole === PostAuthorRole.CLUB
          ? (clubByUserId.get(authorId) ?? null)
          : photo.authorRole === PostAuthorRole.COACH
            ? (coachByUserId.get(authorId) ?? null)
            : (playerByUserId.get(authorId) ?? null);
      result.set(photo._id.toString(), author);
    }
    return result;
  }

  // --- Moderation -------------------------------------------------------
  //
  // Two separate powers, deliberately not collapsed into one:
  //   * delete  — the author's own post, or any post if you moderate.
  //   * hide    — moderators only, and reversible.
  // Hiding is the one a moderator should reach for first: it takes the post
  // out of the feed without destroying the author's media, and it can be
  // undone. Deleting removes the Cloudinary asset, so it is final.

  private assertCanModerate(viewer: FeedViewer): void {
    if (viewer.isModerator === true || viewer.role === UserRole.ADMIN) return;
    throw new ForbiddenException(
      'Only a moderator can change a post’s visibility.',
    );
  }

  async deleteFeedItem(
    viewer: FeedViewer,
    kind: FeedItemKind,
    id: string,
  ): Promise<void> {
    const canModerate =
      viewer.isModerator === true || viewer.role === UserRole.ADMIN;

    if (kind === 'VIDEO') {
      if (canModerate) {
        await this.videosService.moderateDelete(id);
      } else {
        // Owner-scoped: this throws NotFound for someone else's video.
        await this.videosService.deleteVideo(viewer.userId as string, id);
      }
      return;
    }

    const photo = await this.findPhotoOrThrow(id);
    if (!canModerate && photo.authorUserId.toString() !== viewer.userId) {
      throw new ForbiddenException('You can only delete your own posts.');
    }
    await this.cloudinary.deleteAsset(photo.publicId, 'image');
    await this.photoModel.deleteOne({ _id: photo._id });
    await Promise.all([
      this.photoLikeModel.deleteMany({ photoId: photo._id }),
      this.photoCommentModel.deleteMany({ photoId: photo._id }),
    ]);
  }

  async setFeedItemHidden(
    viewer: FeedViewer,
    kind: FeedItemKind,
    id: string,
    hidden: boolean,
  ): Promise<void> {
    this.assertCanModerate(viewer);

    if (kind === 'VIDEO') {
      await this.videosService.moderateSetHidden(id, hidden);
      return;
    }

    const photo = await this.findPhotoOrThrow(id);
    photo.isHidden = hidden;
    photo.hiddenByUserId = hidden
      ? new Types.ObjectId(viewer.userId)
      : undefined;
    photo.hiddenAt = hidden ? new Date() : undefined;
    await photo.save();
  }

  countAllPosts(): Promise<number> {
    return this.photoModel.countDocuments();
  }

  countHiddenPosts(): Promise<number> {
    return this.photoModel.countDocuments({ isHidden: true });
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
    const coachUserIds = users
      .filter((u) => u.role === 'COACH')
      .map((u) => u._id.toString());

    const [profiles, clubProfiles, coachProfiles] = await Promise.all([
      playerUserIds.length
        ? this.playerProfileModel.find({ userId: { $in: playerUserIds } })
        : Promise.resolve([]),
      clubUserIds.length
        ? this.clubProfileModel.find({ userId: { $in: clubUserIds } })
        : Promise.resolve([]),
      coachUserIds.length
        ? this.coachProfileModel.find({ userId: { $in: coachUserIds } })
        : Promise.resolve([]),
    ]);
    const coachProfileByUserId = new Map(
      coachProfiles.map((p) => [p.userId.toString(), p]),
    );
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
      if (user.role === 'COACH') {
        const profile = coachProfileByUserId.get(id);
        const name = [profile?.firstName, profile?.lastName]
          .filter(Boolean)
          .join(' ')
          .trim();
        authorInfoById.set(id, {
          displayName: name || user.email || 'Coach',
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

  // Cascade helper for UsersService.deleteById — the photo-post equivalent
  // of VideosService.deleteAllForPlayer + deleteUserFootprint in one: every
  // post this user authored (with its Cloudinary asset and the likes/
  // comments on it), then the likes/comments they left on other people's
  // posts, with those posts' counters brought back down to match.
  async deleteAllForUser(userId: string): Promise<void> {
    const authorId = new Types.ObjectId(userId);
    const photos = await this.photoModel.find({ authorUserId: authorId });
    if (photos.length > 0) {
      await Promise.all(
        photos.map((photo) =>
          this.cloudinary.deleteAsset(photo.publicId, 'image'),
        ),
      );
      const photoIds = photos.map((photo) => photo._id);
      await Promise.all([
        this.photoModel.deleteMany({ _id: { $in: photoIds } }),
        this.photoLikeModel.deleteMany({ photoId: { $in: photoIds } }),
        this.photoCommentModel.deleteMany({ photoId: { $in: photoIds } }),
      ]);
    }

    const [likes, comments] = await Promise.all([
      this.photoLikeModel.find({ userId: authorId }),
      this.photoCommentModel.find({ userId: authorId }),
    ]);
    await Promise.all([
      this.photoLikeModel.deleteMany({ userId: authorId }),
      this.photoCommentModel.deleteMany({ userId: authorId }),
    ]);
    await Promise.all([
      ...likes.map((like) =>
        this.photoModel.updateOne(
          { _id: like.photoId, likeCount: { $gt: 0 } },
          { $inc: { likeCount: -1 } },
        ),
      ),
      ...comments.map((comment) =>
        this.photoModel.updateOne(
          { _id: comment.photoId, commentCount: { $gt: 0 } },
          { $inc: { commentCount: -1 } },
        ),
      ),
    ]);
  }
}
