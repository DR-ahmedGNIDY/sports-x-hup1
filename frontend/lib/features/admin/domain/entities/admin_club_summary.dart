class AdminClubSummary {
  const AdminClubSummary({
    required this.id,
    required this.isVerified,
    this.name,
    this.country,
    this.city,
  });

  final String id;
  final String? name;
  final String? country;
  final String? city;

  /// Whether an admin has granted this club the verification check mark.
  /// Public once granted — it renders next to the club's name throughout
  /// the app, not only in the dashboard.
  final bool isVerified;
}
