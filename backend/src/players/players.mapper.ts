import { PlayerProfileDocument } from './schemas/player-profile.schema';

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
