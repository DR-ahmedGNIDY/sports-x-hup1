class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.year,
    this.description,
  });

  final String id;
  final String title;
  final int year;
  final String? description;
}
