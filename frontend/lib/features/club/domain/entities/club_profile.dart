class ClubProfile {
  const ClubProfile({
    required this.id,
    this.name,
    this.country,
    this.city,
    this.logoUrl,
    this.description,
    this.foundedYear,
    this.level,
  });

  final String id;
  final String? name;
  final String? country;
  final String? city;
  final String? logoUrl;
  final String? description;
  final int? foundedYear;
  final String? level;
}
