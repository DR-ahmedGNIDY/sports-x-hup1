/// The public-facing identity of a video's owner, embedded in community
/// feed items. `null` fields are rendered defensively (missing photo,
/// missing name) — the backend only guarantees `playerId`.
class VideoAuthor {
  const VideoAuthor({
    required this.playerId,
    this.firstName,
    this.lastName,
    this.profilePhotoUrl,
    this.country,
  });

  final String playerId;
  final String? firstName;
  final String? lastName;
  final String? profilePhotoUrl;
  final String? country;

  String get fullName => [
    firstName,
    lastName,
  ].where((part) => part != null && part.isNotEmpty).join(' ');
}
