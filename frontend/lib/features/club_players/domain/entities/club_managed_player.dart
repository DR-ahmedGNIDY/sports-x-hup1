import '../../../player/domain/entities/player_profile.dart';

/// A player account this club created directly — wraps the same
/// [PlayerProfile] shape the player feature already uses (the backend
/// returns the identical owner view), plus the two fields only a club
/// needs: which user account to target for update/photo/resend-credentials
/// calls, and the dial code used to build a wa.me link.
class ClubManagedPlayer {
  const ClubManagedPlayer({
    required this.userId,
    required this.dialCode,
    required this.profile,
  });

  final String userId;
  final String dialCode;
  final PlayerProfile profile;
}
