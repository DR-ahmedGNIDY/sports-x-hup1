class ClubProfile {
  const ClubProfile({
    required this.id,
    this.publicCode,
    this.name,
    this.country,
    this.city,
    this.logoUrl,
    this.description,
    this.foundedYear,
    this.level,
    this.isVerified = false,
  });

  final String id;

  /// The club's shareable public identifier — `CLB-000123`. Assigned once
  /// by the backend and never rewritten; a player joins by quoting it.
  /// `null` on a profile that predates the feature and hasn't been
  /// backfilled yet.
  final String? publicCode;

  final String? name;
  final String? country;
  final String? city;
  final String? logoUrl;
  final String? description;
  final int? foundedYear;
  final String? level;

  /// Whether an admin has granted this club the verification check mark.
  /// Set only from the admin dashboard; every other surface just renders
  /// the badge.
  final bool isVerified;
}
