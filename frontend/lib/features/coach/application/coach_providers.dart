import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/health_check_provider.dart'
    show apiClientProvider;
import '../../auth/application/session_controller.dart';
import '../../auth/domain/entities/user_role.dart';
import '../../calendar_events/application/calendar_events_controller.dart';
import '../../club/application/club_profile_controller.dart';
import '../../club_players/application/club_players_controller.dart';
import '../../invitations/application/invitations_controller.dart';
import '../../invitations/application/memberships_providers.dart';
import '../../player/domain/entities/contact_details.dart';
import '../../player/domain/entities/player_enums.dart';
import '../data/coach_repository.dart';
import '../domain/coach_models.dart';

// ------------------------------------------------------------ own CV

/// The signed-in coach's own CV. Every mutation returns the full profile
/// from the server and replaces state with it — same contract as
/// PlayerProfileController.
class MyCoachProfileController extends AsyncNotifier<CoachProfile> {
  CoachRepository get _repo => ref.read(coachRepositoryProvider);

  @override
  Future<CoachProfile> build() => _repo.getMyProfile();

  Future<void> _apply(Future<CoachProfile> update) async {
    state = AsyncData(await update);
  }

  Future<void> save({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? country,
    String? city,
    String? sport,
    String? headline,
    int? yearsOfExperience,
    String? bio,
    String? education,
    List<String>? specialties,
    List<String>? preferredFormations,
    List<String>? languages,
    ContactDetails? contact,
  }) => _apply(
    _repo.updateMyProfile(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      country: country,
      city: city,
      sport: sport,
      headline: headline,
      yearsOfExperience: yearsOfExperience,
      bio: bio,
      education: education,
      specialties: specialties,
      preferredFormations: preferredFormations,
      languages: languages,
      contact: contact,
    ),
  );

  Future<void> setVisibility(ProfileVisibility visibility) =>
      _apply(_repo.setVisibility(visibility));

  Future<void> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) => _apply(_repo.uploadProfilePhoto(bytes: bytes, filename: filename));

  Future<void> uploadMedia({
    required List<int> bytes,
    required String filename,
    required PlayerMediaType type,
  }) => _apply(_repo.uploadMedia(bytes: bytes, filename: filename, type: type));

  Future<void> deleteMedia(String id) => _apply(_repo.deleteMedia(id));

  Future<void> addEntry(CoachCvSection section, Map<String, dynamic> body) =>
      _apply(_repo.addEntry(section, body));

  Future<void> updateEntry(
    CoachCvSection section,
    String id,
    Map<String, dynamic> body,
  ) => _apply(_repo.updateEntry(section, id, body));

  Future<void> removeEntry(CoachCvSection section, String id) =>
      _apply(_repo.removeEntry(section, id));
}

final myCoachProfileProvider =
    AsyncNotifierProvider<MyCoachProfileController, CoachProfile>(
      MyCoachProfileController.new,
    );

final publicCoachProfileProvider = FutureProvider.autoDispose
    .family<CoachProfile, String>(
      (ref, id) => ref.read(coachRepositoryProvider).getPublicProfile(id),
    );

final clubPublicStaffProvider = FutureProvider.autoDispose
    .family<List<CoachSummary>, String>(
      (ref, clubProfileId) =>
          ref.read(coachRepositoryProvider).clubStaffPublic(clubProfileId),
    );

// ------------------------------------------------- the coach's clubs

/// Every club the signed-in coach works for. Empty for any other role.
final myCoachClubsProvider = FutureProvider<List<CoachClubMembership>>((
  ref,
) async {
  final user = ref.watch(sessionControllerProvider.select((s) => s.user));
  if (user?.role != UserRole.coach) return const [];
  return ref.read(coachRepositoryProvider).myClubs();
});

/// Which of their clubs a coach is acting for right now — and the single
/// owner of the `X-Club-Id` header [ApiClient] sends. `null` for anyone who
/// is not a coach, and for a coach with no club yet.
///
/// The choice is remembered per account, so reopening the app lands the
/// coach back on the club they were working on.
class ActiveClubController extends AsyncNotifier<CoachClubMembership?> {
  static String _prefsKey(String userId) => 'activeClubId:$userId';

  @override
  Future<CoachClubMembership?> build() async {
    final userId = ref.watch(
      sessionControllerProvider.select((s) => s.user?.id),
    );
    final clubs = await ref.watch(myCoachClubsProvider.future);
    if (userId == null || clubs.isEmpty) {
      _setHeader(null);
      return null;
    }
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(
        _prefsKey(userId),
      );
    } catch (_) {
      // Storage unavailable (private window, tests): just pick the first.
    }
    final active = clubs.firstWhere(
      (m) => m.club?.id == saved,
      orElse: () => clubs.first,
    );
    _setHeader(active.club?.id);
    return active;
  }

  void _setHeader(String? clubProfileId) {
    ref.read(apiClientProvider).clubContextId = clubProfileId;
  }

  Future<void> select(CoachClubMembership membership) async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    _setHeader(membership.club?.id);
    state = AsyncData(membership);
    if (userId != null && membership.club != null) {
      try {
        await (await SharedPreferences.getInstance()).setString(
          _prefsKey(userId),
          membership.club!.id,
        );
      } catch (_) {}
    }
    _resetClubScopedState();
  }

  // Everything below was fetched *as* the previous club. Dropping it makes
  // each screen refetch under the new header instead of showing one club's
  // roster under another's name.
  void _resetClubScopedState() {
    ref
      ..invalidate(clubProfileControllerProvider)
      ..invalidate(clubPlayersControllerProvider)
      ..invalidate(clubManagedPlayerProvider)
      ..invalidate(clubDashboardSummaryProvider)
      ..invalidate(calendarEventsProvider)
      ..invalidate(calendarEventProvider)
      ..invalidate(rosterPoolProvider)
      ..invalidate(invitationsListProvider)
      ..invalidate(invitationsSummaryProvider)
      ..invalidate(clubMembersProvider);
  }
}

final activeClubProvider =
    AsyncNotifierProvider<ActiveClubController, CoachClubMembership?>(
      ActiveClubController.new,
    );

/// Whether the signed-in account may do [permission] for the club it is
/// acting for: always for a club account, per grant for a coach, never for
/// anyone else. Drives which buttons the shared club screens show — the
/// server enforces the same rule on its own either way.
final clubPermissionProvider = Provider.family<bool, CoachPermission>((
  ref,
  permission,
) {
  final role = ref.watch(sessionControllerProvider.select((s) => s.user?.role));
  if (role == UserRole.club) return true;
  if (role != UserRole.coach) return false;
  return ref.watch(activeClubProvider).valueOrNull?.can(permission) ?? false;
});

// ------------------------------------------------ club staff (club side)

final clubStaffProvider = FutureProvider.autoDispose<List<StaffMember>>(
  (ref) => ref.read(coachRepositoryProvider).clubStaff(),
);

/// Club↔coach invitations for whoever is signed in (a club or a coach).
final coachInvitationsProvider = FutureProvider.autoDispose
    .family<List<CoachInvitation>, bool>(
      (ref, received) =>
          ref.read(coachRepositoryProvider).invitations(received: received),
    );
