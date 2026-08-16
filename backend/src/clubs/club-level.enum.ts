// Controlled values for ClubProfile.level, replacing the old free-text
// field. Stable, language-independent strings — never store a translated
// label here, the frontend maps these to a localized display string.
//
// The schema field itself (see schemas/club-profile.schema.ts) stays a
// plain `String`, not a Mongoose-level enum: existing clubs may already
// have an arbitrary free-text value saved before this enum existed, and a
// schema-level enum validator would reject *any* save on that document
// (even one unrelated to `level`) until the club happened to fix it. Only
// new writes are constrained, via `@IsEnum(ClubLevel)` on
// `UpdateClubProfileDto` — a legacy value is left exactly as it is until
// the club edits its level again.
export enum ClubLevel {
  AMATEUR = 'amateur',
  SEMI_PROFESSIONAL = 'semi_professional',
  PROFESSIONAL = 'professional',
}
