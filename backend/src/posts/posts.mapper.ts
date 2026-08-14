import { ClubProfileDocument } from '../clubs/schemas/club-profile.schema';
import { profilePhotoUrl } from '../players/players.mapper';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { VideoDocument } from '../videos/schemas/video.schema';
import { PhotoCommentDocument } from './schemas/photo-comment.schema';
import { PhotoPostDocument, PostAuthorRole } from './schemas/photo-post.schema';

// One author shape for both a Player and a Club poster, so the Home feed
// card doesn't have to branch on who made the post — only on `kind`
// (VIDEO/PHOTO) for how to render the media itself.
export interface FeedAuthorView {
  role: 'PLAYER' | 'CLUB';
  playerId?: string;
  clubId?: string;
  displayName: string;
  profilePhotoUrl?: string;
  country?: string;
}

function playerAuthorView(
  profile: PlayerProfileDocument | null,
): FeedAuthorView | null {
  if (!profile) return null;
  const name = [profile.firstName, profile.lastName]
    .filter(Boolean)
    .join(' ')
    .trim();
  return {
    role: 'PLAYER',
    playerId: profile._id.toString(),
    displayName: name || 'Player',
    profilePhotoUrl: profilePhotoUrl(profile),
    country: profile.country,
  };
}

function clubAuthorView(
  profile: ClubProfileDocument | null,
): FeedAuthorView | null {
  if (!profile) return null;
  return {
    role: 'CLUB',
    clubId: profile._id.toString(),
    displayName: profile.name || 'Club',
    profilePhotoUrl: profile.logo?.secureUrl,
    country: profile.country,
  };
}

// A unified Home-feed item — one shape for both a Video and a Photo post,
// distinguished by `kind`, so the frontend renders one card component
// instead of branching on the source collection. Deliberately a fresh
// shape (not videos.mapper's `toFeedItemView`) rather than reusing it: the
// existing Community feed's response contract is load-bearing for the
// frontend already and must not change just because Home now needs a
// slightly different (unified-author) shape.
export function videoFeedItem(
  video: VideoDocument,
  authorProfile: PlayerProfileDocument | null,
) {
  return {
    kind: 'VIDEO' as const,
    id: video._id.toString(),
    secureUrl: video.secureUrl,
    // Same derivation as videos.mapper's deriveThumbnailUrl — Cloudinary
    // serves a video's auto-generated thumbnail at the same publicId with
    // a `.jpg` extension, so there's nothing stored/uploaded separately.
    thumbnailUrl:
      video.thumbnailUrl ?? video.secureUrl.replace(/\.[^./]+$/, '.jpg'),
    caption: video.title,
    sport: video.sport,
    likeCount: video.likeCount,
    commentCount: video.commentCount,
    createdAt: (video as VideoDocument & { createdAt: Date }).createdAt,
    author: playerAuthorView(authorProfile),
  };
}

export function photoFeedItem(
  photo: PhotoPostDocument,
  authorProfile: PlayerProfileDocument | ClubProfileDocument | null,
) {
  return {
    kind: 'PHOTO' as const,
    id: photo._id.toString(),
    secureUrl: photo.secureUrl,
    thumbnailUrl: photo.secureUrl,
    caption: photo.caption,
    sport: photo.sport,
    likeCount: photo.likeCount,
    commentCount: photo.commentCount,
    createdAt: (photo as PhotoPostDocument & { createdAt: Date }).createdAt,
    author:
      photo.authorRole === PostAuthorRole.CLUB
        ? clubAuthorView(authorProfile as ClubProfileDocument | null)
        : playerAuthorView(authorProfile as PlayerProfileDocument | null),
  };
}

export function toCommentView(
  comment: PhotoCommentDocument,
  authorDisplayName: string,
  authorRole: string,
  currentUserId: string,
) {
  return {
    id: comment._id.toString(),
    text: comment.text,
    createdAt: (comment as PhotoCommentDocument & { createdAt: Date })
      .createdAt,
    authorDisplayName,
    authorRole,
    isMine: comment.userId.toString() === currentUserId,
  };
}
