class AdminPlayerSummary {
  const AdminPlayerSummary({
    required this.id,
    this.firstName,
    this.lastName,
    this.sport,
    this.position,
    this.visibility,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? sport;
  final String? position;
  final String? visibility;

  String get fullName => [
    firstName,
    lastName,
  ].where((part) => part != null && part.isNotEmpty).join(' ');
}
