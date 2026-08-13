/// A player's profile photo — stored separately from the [PlayerMedia]
/// album on the backend, so it's modeled separately here too.
class ProfilePhoto {
  const ProfilePhoto({required this.secureUrl});

  final String secureUrl;
}
