import {
  MediaType,
  PlayerProfileDocument,
} from './schemas/player-profile.schema';

// Each key doubles as the i18n lookup the frontend uses to render the
// "complete your profile" checklist, so keep these stable — renaming one
// is a breaking change for that screen, not just a refactor here.
const COMPLETION_CHECKS: Record<
  string,
  (profile: PlayerProfileDocument) => boolean
> = {
  firstName: (p) => Boolean(p.firstName),
  lastName: (p) => Boolean(p.lastName),
  dateOfBirth: (p) => Boolean(p.dateOfBirth),
  nationality: (p) => Boolean(p.nationality),
  country: (p) => Boolean(p.country),
  city: (p) => Boolean(p.city),
  sport: (p) => Boolean(p.sport),
  position: (p) => Boolean(p.position),
  bio: (p) => Boolean(p.bio),
  profilePhoto: (p) => Boolean(profilePhotoUrl(p)),
  contact: (p) =>
    Boolean(p.contact?.phone || p.contact?.email || p.contact?.whatsapp),
  achievements: (p) => p.achievements.length > 0,
  socialLinks: (p) => p.socialLinks.length > 0,
};

function ageFromDateOfBirth(dateOfBirth?: Date): number | undefined {
  if (!dateOfBirth) return undefined;
  const diffMs = Date.now() - dateOfBirth.getTime();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24 * 365.25));
}

export function profilePhotoUrl(
  profile: PlayerProfileDocument,
): string | undefined {
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

// GET /players/me/stats — powers the Player Dashboard's completion card
// and quick-stats tiles. `savedByClubsCount` is computed by the service
// (it needs the SavedPlayer collection, not just the profile document).
export function toStatsView(
  profile: PlayerProfileDocument,
  savedByClubsCount: number,
) {
  const missingFields = Object.entries(COMPLETION_CHECKS)
    .filter(([, check]) => !check(profile))
    .map(([key]) => key);
  const totalChecks = Object.keys(COMPLETION_CHECKS).length;
  const completedChecks = totalChecks - missingFields.length;

  return {
    completionPercent: Math.round((completedChecks / totalChecks) * 100),
    missingFields,
    visibility: profile.visibility,
    mediaCount: profile.media.length,
    achievementsCount: profile.achievements.length,
    savedByClubsCount,
  };
}
