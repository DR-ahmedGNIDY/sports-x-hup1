import { ClubProfileDocument } from './schemas/club-profile.schema';

function baseView(profile: ClubProfileDocument) {
  return {
    id: profile._id.toString(),
    // Shown on the public profile and used to search for this club.
    // Undefined only for profiles still awaiting the backfill.
    publicCode: profile.publicCode,
    name: profile.name,
    country: profile.country,
    city: profile.city,
    logo: profile.logo,
    description: profile.description,
    foundedYear: profile.foundedYear,
    level: profile.level,
  };
}

// Owner view and public view are identical — a club profile has no
// private fields (no visibility setting, no contact details) to gate.
export function toClubView(profile: ClubProfileDocument) {
  return baseView(profile);
}
