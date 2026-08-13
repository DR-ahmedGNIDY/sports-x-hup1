import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ClubProfile } from '../clubs/schemas/club-profile.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { ALLOWED_VIDEO_MIME_TYPES } from '../common/upload.config';
import { PlayerProfile } from '../players/schemas/player-profile.schema';
import { SportsService } from '../sports/sports.service';
import { User } from '../users/schemas/user.schema';
import { CreateCommentDto } from './dto/create-comment.dto';
import { UploadVideoDto } from './dto/upload-video.dto';
import { toCommentView, toFeedItemView, toOwnerVideoView } from './videos.mapper';
import { VideoComment, VideoCommentDocument } from './schemas/video-comment.schema';
import { VideoLike } from './schemas/video-like.schema';
import { Video, VideoDocument, VideoVisibility } from './schemas/video.schema';

const DUPLICATE_KEY_ERROR_CODE = 11000;
const COMMUNITY_FEED_PAGE_SIZE = 12;
const COMMENTS_PAGE_SIZE = 20;

export interface CommunityFeedResult {
  items: ReturnType<typeof toFeedItemView>[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class VideosService {
  constructor(
    @InjectModel(Video.name) private readonly videoModel: Model<Video>,
    @InjectModel(VideoLike.name) private readonly videoLikeModel: Model<VideoLike>,
    @InjectModel(VideoComment.name)
    private readonly videoCommentModel: Model<VideoComment>,
    @InjectModel(PlayerProfile.name)
    private readonly playerProfileModel: Model<PlayerProfile>,
    @InjectModel(ClubProfile.name)
    private readonly clubProfileModel: Model<ClubProfile>,
    @InjectModel(User.name) private readonly userModel: Model<User>,
    private readonly cloudinary: CloudinaryService,
    private readonly sportsService: SportsService,
  ) {}

  private async getOwnPlayerProfileOrThrow(userId: string) {
    const profile = await this.playerProfileModel.findOne({ userId });
    if (!profile) {
      throw new NotFoundException(
        'You must have a player profile before uploading a video.',
      );
    }
    return profile;
  }

  private async findVideoOrThrow(videoId: string): Promise<VideoDocument> {
    if (!Types.ObjectId.isValid(videoId)) {
      throw new NotFoundException('Video not found.');
    }
    const video = await this.videoModel.findById(videoId);
    if (!video) {
      throw new NotFoundException('Video not found.');
    }
    return video;
  }

  private assertViewable(video: VideoDocument, userId: string): void {
    if (
      video.visibility !== VideoVisibility.PUBLIC &&
      video.userId.toString() !== userId
    ) {
      throw new NotFoundException('Video not found.');
    }
  }

  async uploadVideo(
    userId: string,
    dto: UploadVideoDto,
    file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('A file is required.');
    }
    // Defensive re-check: `videoUploadOptions`' fileFilter already rejects
    // non-video mimetypes before Multer buffers the file, but re-verify
    // here too rather than trusting the interceptor was the only gate.
    if (!ALLOWED_VIDEO_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `A video upload must be one of: ${ALLOWED_VIDEO_MIME_TYPES.join(', ')}.`,
      );
    }
    const profile = await this.getOwnPlayerProfileOrThrow(userId);
    // `Video.sport` is required, but `PlayerProfile.sport` is optional —
    // without this check a player who never set a sport would hit an
    // unhandled Mongoose ValidationError (500) on `videoModel.create`.
    if (!profile.sport) {
      throw new BadRequestException(
        'Set your sport on your profile before uploading a video.',
      );
    }
    await this.sportsService.assertCategoryExists(profile.sport, dto.category);

    const upload = await this.cloudinary.uploadBuffer(
      file.buffer,
      `sportxhub/videos/${userId}`,
      'video',
    );
    let video: VideoDocument;
    try {
      video = await this.videoModel.create({
        playerId: profile._id,
        userId,
        sport: profile.sport,
        category: dto.category,
        title: dto.title,
        visibility: dto.visibility,
        publicId: upload.publicId,
        secureUrl: upload.secureUrl,
      });
    } catch (error) {
      // The Cloudinary asset already landed — without this the DB write
      // failing would leave it orphaned (never referenced, never cleaned
      // up) while the caller gets a raw 500.
      await this.cloudinary.deleteAsset(upload.publicId, 'video');
      throw error;
    }
    return toOwnerVideoView(video);
  }

  async listMine(userId: string, category?: string) {
    const profile = await this.getOwnPlayerProfileOrThrow(userId);
    const videos = await this.videoModel
      .find({ playerId: profile._id, ...(category && { category }) })
      .sort({ createdAt: -1 });
    return videos.map(toOwnerVideoView);
  }

  async listForPlayer(playerId: string, category?: string) {
    if (!Types.ObjectId.isValid(playerId)) {
      return [];
    }
    const videos = await this.videoModel
      .find({
        playerId,
        visibility: VideoVisibility.PUBLIC,
        ...(category && { category }),
      })
      .sort({ createdAt: -1 });
    return videos.map((video) => toFeedItemView(video, null));
  }

  async updateVisibility(
    userId: string,
    videoId: string,
    visibility: VideoVisibility,
  ) {
    const video = await this.findVideoOrThrow(videoId);
    if (video.userId.toString() !== userId) {
      throw new NotFoundException('Video not found.');
    }
    video.visibility = visibility;
    await video.save();
    return toOwnerVideoView(video);
  }

  async updateTitle(userId: string, videoId: string, title: string | undefined) {
    const video = await this.findVideoOrThrow(videoId);
    if (video.userId.toString() !== userId) {
      throw new NotFoundException('Video not found.');
    }
    video.title = title;
    await video.save();
    return toOwnerVideoView(video);
  }

  async deleteVideo(userId: string, videoId: string): Promise<void> {
    const video = await this.findVideoOrThrow(videoId);
    if (video.userId.toString() !== userId) {
      throw new NotFoundException('Video not found.');
    }
    await this.cloudinary.deleteAsset(video.publicId, 'video');
    await this.videoModel.deleteOne({ _id: video._id });
    await Promise.all([
      this.videoLikeModel.deleteMany({ videoId: video._id }),
      this.videoCommentModel.deleteMany({ videoId: video._id }),
    ]);
  }

  async communityFeed(
    sport: string,
    category: string | undefined,
    page = 1,
  ): Promise<CommunityFeedResult> {
    // `category` is deliberately not validated the same way — an unmatched
    // category filter just legitimately returns an empty feed, which is
    // fine, whereas an unknown `sport` is almost certainly a caller error.
    await this.sportsService.assertSportExists(sport);
    const filter: Record<string, unknown> = {
      visibility: VideoVisibility.PUBLIC,
      sport,
      ...(category && { category }),
    };
    const [videos, total] = await Promise.all([
      this.videoModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * COMMUNITY_FEED_PAGE_SIZE)
        .limit(COMMUNITY_FEED_PAGE_SIZE),
      this.videoModel.countDocuments(filter),
    ]);

    const playerIds = [
      ...new Set(videos.map((video) => video.playerId.toString())),
    ];
    const profiles = playerIds.length
      ? await this.playerProfileModel.find({ _id: { $in: playerIds } })
      : [];
    const profileById = new Map(
      profiles.map((profile) => [profile._id.toString(), profile]),
    );

    return {
      items: videos.map((video) =>
        toFeedItemView(
          video,
          profileById.get(video.playerId.toString()) ?? null,
        ),
      ),
      page,
      pageSize: COMMUNITY_FEED_PAGE_SIZE,
      total,
    };
  }

  async like(userId: string, videoId: string) {
    const video = await this.findVideoOrThrow(videoId);
    this.assertViewable(video, userId);
    try {
      await this.videoLikeModel.create({ videoId: video._id, userId });
    } catch (error) {
      if ((error as { code?: number }).code === DUPLICATE_KEY_ERROR_CODE) {
        throw new ConflictException('You have already liked this video.');
      }
      throw error;
    }
    const updated = await this.videoModel.findByIdAndUpdate(
      video._id,
      { $inc: { likeCount: 1 } },
      { new: true },
    );
    return { likeCount: updated?.likeCount ?? video.likeCount + 1, isLikedByMe: true };
  }

  async unlike(userId: string, videoId: string) {
    const video = await this.findVideoOrThrow(videoId);
    this.assertViewable(video, userId);
    const result = await this.videoLikeModel.deleteOne({
      videoId: video._id,
      userId,
    });
    if (result.deletedCount === 0) {
      throw new NotFoundException('You have not liked this video.');
    }
    const updated = await this.videoModel.findByIdAndUpdate(
      video._id,
      { $inc: { likeCount: video.likeCount > 0 ? -1 : 0 } },
      { new: true },
    );
    return {
      likeCount: Math.max(0, updated?.likeCount ?? video.likeCount - 1),
      isLikedByMe: false,
    };
  }

  private async resolveDisplayName(
    userId: Types.ObjectId,
  ): Promise<{ displayName: string; role: string }> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      return { displayName: 'Unknown', role: 'UNKNOWN' };
    }
    if (user.role === 'PLAYER') {
      const profile = await this.playerProfileModel.findOne({ userId });
      const name = [profile?.firstName, profile?.lastName]
        .filter(Boolean)
        .join(' ')
        .trim();
      return {
        displayName: name || user.email || user.phone || 'Player',
        role: user.role,
      };
    }
    if (user.role === 'CLUB') {
      const profile = await this.clubProfileModel.findOne({ userId });
      return {
        displayName: profile?.name || user.email || 'Club',
        role: user.role,
      };
    }
    return { displayName: 'Admin', role: user.role };
  }

  // Batched counterpart to resolveDisplayName — resolves a whole page of
  // comment authors with 3 queries total (users, then players/clubs
  // partitioned by role) instead of one round-trip per unique author.
  // Mirrors the batching style already used in communityFeed().
  private async resolveDisplayNames(
    userIds: string[],
  ): Promise<Map<string, { displayName: string; role: string }>> {
    const authorInfoById = new Map<
      string,
      { displayName: string; role: string }
    >();
    if (userIds.length === 0) {
      return authorInfoById;
    }

    const users = await this.userModel.find({ _id: { $in: userIds } });
    const userById = new Map(users.map((user) => [user._id.toString(), user]));

    const playerUserIds = users
      .filter((user) => user.role === 'PLAYER')
      .map((user) => user._id.toString());
    const clubUserIds = users
      .filter((user) => user.role === 'CLUB')
      .map((user) => user._id.toString());

    const [profiles, clubProfiles] = await Promise.all([
      playerUserIds.length
        ? this.playerProfileModel.find({ userId: { $in: playerUserIds } })
        : Promise.resolve([]),
      clubUserIds.length
        ? this.clubProfileModel.find({ userId: { $in: clubUserIds } })
        : Promise.resolve([]),
    ]);
    const profileByUserId = new Map(
      profiles.map((profile) => [profile.userId.toString(), profile]),
    );
    const clubProfileByUserId = new Map(
      clubProfiles.map((profile) => [profile.userId.toString(), profile]),
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

  async listComments(userId: string, videoId: string, page = 1) {
    const video = await this.findVideoOrThrow(videoId);
    this.assertViewable(video, userId);
    const comments = await this.videoCommentModel
      .find({ videoId: video._id })
      .sort({ createdAt: 1 })
      .skip((page - 1) * COMMENTS_PAGE_SIZE)
      .limit(COMMENTS_PAGE_SIZE);

    const uniqueAuthorIds = [
      ...new Set(comments.map((comment) => comment.userId.toString())),
    ];
    const authorInfoById = await this.resolveDisplayNames(uniqueAuthorIds);

    return comments.map((comment) => {
      const info = authorInfoById.get(comment.userId.toString()) ?? {
        displayName: 'Unknown',
        role: 'UNKNOWN',
      };
      return toCommentView(comment, info.displayName, info.role, userId);
    });
  }

  async addComment(userId: string, videoId: string, dto: CreateCommentDto) {
    const video = await this.findVideoOrThrow(videoId);
    this.assertViewable(video, userId);
    const comment = await this.videoCommentModel.create({
      videoId: video._id,
      userId,
      text: dto.text,
    });
    await this.videoModel.updateOne(
      { _id: video._id },
      { $inc: { commentCount: 1 } },
    );
    const info = await this.resolveDisplayName(new Types.ObjectId(userId));
    return toCommentView(comment, info.displayName, info.role, userId);
  }

  async deleteComment(
    userId: string,
    role: string,
    videoId: string,
    commentId: string,
  ): Promise<void> {
    const video = await this.findVideoOrThrow(videoId);
    this.assertViewable(video, userId);
    if (!Types.ObjectId.isValid(commentId)) {
      throw new NotFoundException('Comment not found.');
    }
    const comment = await this.videoCommentModel.findOne({
      _id: commentId,
      videoId: video._id,
    });
    if (!comment) {
      throw new NotFoundException('Comment not found.');
    }
    if (comment.userId.toString() !== userId && role !== 'ADMIN') {
      throw new ForbiddenException('You do not have access to this comment.');
    }
    await this.videoCommentModel.deleteOne({ _id: comment._id });
    await this.videoModel.updateOne(
      { _id: video._id, commentCount: { $gt: 0 } },
      { $inc: { commentCount: -1 } },
    );
  }

  // Cascade helper reused by PlayersService.deleteProfileAndMedia (a player
  // deleting/being deleted) — removes every video this player owns (with
  // its Cloudinary asset) plus the likes/comments attached to those videos,
  // so a deleted profile never leaves `author: null` entries in the
  // Community feed or orphaned Cloudinary assets behind.
  async deleteAllForPlayer(playerId: string): Promise<void> {
    const videos = await this.videoModel.find({ playerId });
    if (videos.length === 0) {
      return;
    }
    await Promise.all(
      videos.map((video) => this.cloudinary.deleteAsset(video.publicId, 'video')),
    );
    const videoIds = videos.map((video) => video._id);
    await Promise.all([
      this.videoModel.deleteMany({ playerId }),
      this.videoLikeModel.deleteMany({ videoId: { $in: videoIds } }),
      this.videoCommentModel.deleteMany({ videoId: { $in: videoIds } }),
    ]);
  }

  // Cascade helper reused by UsersService.deleteById — cleans up this
  // user's footprint as a *viewer* of other people's videos (likes and
  // comments they left elsewhere). Their own videos are handled separately
  // by deleteAllForPlayer via PlayersService's cascade.
  async deleteUserFootprint(userId: string): Promise<void> {
    const [likes, comments] = await Promise.all([
      this.videoLikeModel.find({ userId }),
      this.videoCommentModel.find({ userId }),
    ]);
    await Promise.all([
      this.videoLikeModel.deleteMany({ userId }),
      this.videoCommentModel.deleteMany({ userId }),
    ]);
    await Promise.all([
      ...likes.map((like) =>
        this.videoModel.updateOne(
          { _id: like.videoId, likeCount: { $gt: 0 } },
          { $inc: { likeCount: -1 } },
        ),
      ),
      ...comments.map((comment) =>
        this.videoModel.updateOne(
          { _id: comment.videoId, commentCount: { $gt: 0 } },
          { $inc: { commentCount: -1 } },
        ),
      ),
    ]);
  }
}
