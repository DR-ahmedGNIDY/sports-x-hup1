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
}
