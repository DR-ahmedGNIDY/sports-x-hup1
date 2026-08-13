/// Login credentials for a club-created player account — the plaintext
/// password is only ever available right after a create/resend call, never
/// stored or fetchable again afterwards.
class ClubPlayerCredentials {
  const ClubPlayerCredentials({required this.username, required this.password});

  final String username;
  final String password;
}
