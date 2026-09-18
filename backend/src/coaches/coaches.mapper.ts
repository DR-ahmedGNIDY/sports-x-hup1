import { CoachProfileDocument } from './schemas/coach-profile.schema';

// Keys double as the i18n lookup for the "complete your CV" checklist on the
// client, so keep them stable.
const COMPLETION_CHECKS: Record<
  string,
  (profile: CoachProfileDocument) => boolean
> = {
  firstName: (p) => Boolean(p.firstName),
  lastName: (p) => Boolean(p.lastName),
  headline: (p) => Boolean(p.headline),
  country: (p) => Boolean(p.country),
  sport: (p) => Boolean(p.sport),
  bio: (p) => Boolean(p.bio),
  profilePhoto: (p) => Boolean(p.profilePhoto?.secureUrl),
  certifications: (p) => p.certifications.length > 0,
  experience: (p) => p.experience.length > 0,
  contact: (p) =>
    Boolean(p.contact?.phone || p.contact?.email || p.contact?.whatsapp),
};

export function coachMissingFields(profile: CoachProfileDocument): string[] {
  return Object.entries(COMPLETION_CHECKS)
    .filter(([, check]) => !check(profile))
    .map(([key]) => key);
}

export function coachDisplayName(
  profile: CoachProfileDocument | null | undefined,
): string | undefined {
  const name = [profile?.firstName, profile?.lastName]
    .filter((part) => part && part.length > 0)
    .join(' ');
  return name.length > 0 ? name : undefined;
}

// A club the coach currently works with, as shown on the CV. Built by the
// caller from the coach's active memberships.
export interface CoachClubView {
  id: string;
  name?: string;
  logoUrl?: string;
  publicCode?: string;
  joinedAt: Date;
}

function baseView(profile: CoachProfileDocument, clubs: CoachClubView[]) {
  return {
    id: profile._id.toString(),
    publicCode: profile.publicCode,
    firstName: profile.firstName,
    lastName: profile.lastName,
    dateOfBirth: profile.dateOfBirth,
    nationality: profile.nationality,
    country: profile.country,
    city: profile.city,
    sport: profile.sport,
    headline: profile.headline,
    yearsOfExperience: profile.yearsOfExperience,
    bio: profile.bio,
    education: profile.education,
    specialties: profile.specialties,
    preferredFormations: profile.preferredFormations,
    languages: profile.languages,
    profilePhoto: profile.profilePhoto,
    media: profile.media,
    certifications: profile.certifications,
    experience: profile.experience,
    achievements: profile.achievements,
    socialLinks: profile.socialLinks,
    currentClubs: clubs,
  };
}

export function toCoachOwnerView(
  profile: CoachProfileDocument,
  clubs: CoachClubView[] = [],
) {
  const missingFields = coachMissingFields(profile);
  const total = Object.keys(COMPLETION_CHECKS).length;
  return {
    ...baseView(profile, clubs),
    userId: profile.userId.toString(),
    contact: profile.contact,
    visibility: profile.visibility,
    missingFields,
    completionPercent: Math.round(
      ((total - missingFields.length) / total) * 100,
    ),
  };
}

// Contact details are left out, same rule as the public player view.
export function toCoachPublicView(
  profile: CoachProfileDocument,
  clubs: CoachClubView[] = [],
) {
  return baseView(profile, clubs);
}

export function toCoachSearchResultView(profile: CoachProfileDocument) {
  return {
    id: profile._id.toString(),
    publicCode: profile.publicCode,
    firstName: profile.firstName,
    lastName: profile.lastName,
    headline: profile.headline,
    country: profile.country,
    sport: profile.sport,
    yearsOfExperience: profile.yearsOfExperience,
    profilePhotoUrl: profile.profilePhoto?.secureUrl,
  };
}
