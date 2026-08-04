import {
  MediaType,
  PlayerProfileDocument,
} from './schemas/player-profile.schema';

function ageFromDateOfBirth(dateOfBirth?: Date): number | undefined {
  if (!dateOfBirth) return undefined;
  const diffMs = Date.now() - dateOfBirth.getTime();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24 * 365.25));
}

function profilePhotoUrl(profile: PlayerProfileDocument): string | undefined {
  return profile.media.find(
    (item) => item.type === MediaType.PHOTO && item.isProfilePhoto,
  )?.secureUrl;
}

function baseView(profile: PlayerProfileDocument) {
  return {
    id: profile._id.toString(),
    firstName: profile.firstName,
    lastName: profile.lastName,
    dateOfBirth: profile.dateOfBirth,
    nationality: profile.nationality,
    country: profile.country,
    city: profile.city,
    sport: profile.sport,
    position: profile.position,
    preferredFoot: profile.preferredFoot,
    height: profile.height,
    weight: profile.weight,
    currentStatus: profile.currentStatus,
    currentClub: profile.currentClub,
    bio: profile.bio,
    media: profile.media,
    achievements: profile.achievements,
    socialLinks: profile.socialLinks,
  };
}

// Full view for the owner (Edit Profile / My Profile Preview) — includes
// contact details and visibility regardless of the PUBLIC/PRIVATE setting.
export function toOwnerView(profile: PlayerProfileDocument) {
  return {
    ...baseView(profile),
    userId: profile.userId.toString(),
    contact: profile.contact,
    visibility: profile.visibility,
    createdAt: (profile as PlayerProfileDocument & { createdAt: Date })
      .createdAt,
    updatedAt: (profile as PlayerProfileDocument & { updatedAt: Date })
      .updatedAt,
  };
}

// Public view (GET /players/:id) — reachable by anyone, unauthenticated,
// once visibility is PUBLIC (enforced by the service before this is
// called). Contact details are deliberately excluded here: Phase 3's
// Simple Contact gates phone/email/WhatsApp behind a logged-in Club, so
// this endpoint must not hand them to anonymous scrapers in the meantime.
export function toPublicView(profile: PlayerProfileDocument) {
  return baseView(profile);
}

// Lean shape for player search results and the Saved Players list — a
// results grid/card list doesn't need the full achievements/social-links
// payload per row, just enough to identify and evaluate the player at a
// glance.
export function toSearchResultView(profile: PlayerProfileDocument) {
  return {
    id: profile._id.toString(),
    firstName: profile.firstName,
    lastName: profile.lastName,
    age: ageFromDateOfBirth(profile.dateOfBirth),
    country: profile.country,
    sport: profile.sport,
    position: profile.position,
    preferredFoot: profile.preferredFoot,
    height: profile.height,
    weight: profile.weight,
    profilePhotoUrl: profilePhotoUrl(profile),
  };
}
