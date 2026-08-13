import { profilePhotoUrl } from '../players/players.mapper';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { VideoCommentDocument } from './schemas/video-comment.schema';
import { VideoDocument } from './schemas/video.schema';

// Full view for the video's owner (My Videos) — includes visibility and the
// engagement counters regardless of whether the video is public yet.
export function toOwnerVideoView(video: VideoDocument) {
  return {
    id: video._id.toString(),
    playerId: video.playerId.toString(),
    sport: video.sport,
    category: video.category,
    title: video.title,
    secureUrl: video.secureUrl,
    thumbnailUrl: video.thumbnailUrl,
    visibility: video.visibility,
    likeCount: video.likeCount,
    commentCount: video.commentCount,
    createdAt: (video as VideoDocument & { createdAt: Date }).createdAt,
    updatedAt: (video as VideoDocument & { updatedAt: Date }).updatedAt,
  };
}

// Feed item shape for the Community feed — includes a lightweight author
// summary (or null, if the author profile could no longer be resolved).
export function toFeedItemView(
  video: VideoDocument,
  authorProfile: PlayerProfileDocument | null,
) {
  return {
    id: video._id.toString(),
    secureUrl: video.secureUrl,
    thumbnailUrl: video.thumbnailUrl,
    category: video.category,
    sport: video.sport,
    title: video.title,
    likeCount: video.likeCount,
    commentCount: video.commentCount,
    createdAt: (video as VideoDocument & { createdAt: Date }).createdAt,
    author: authorProfile
      ? {
          playerId: authorProfile._id.toString(),
          firstName: authorProfile.firstName,
          lastName: authorProfile.lastName,
          profilePhotoUrl: profilePhotoUrl(authorProfile),
          country: authorProfile.country,
        }
      : null,
  };
}

export function toCommentView(
  comment: VideoCommentDocument,
  authorDisplayName: string,
  authorRole: string,
  currentUserId: string,
) {
  return {
    id: comment._id.toString(),
    text: comment.text,
    createdAt: (comment as VideoCommentDocument & { createdAt: Date })
      .createdAt,
    authorDisplayName,
    authorRole,
    isMine: comment.userId.toString() === currentUserId,
  };
}
