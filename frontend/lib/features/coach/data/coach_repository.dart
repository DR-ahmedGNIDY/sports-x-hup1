import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/authorized_request.dart';
import '../../../core/providers/health_check_provider.dart'
    show apiClientProvider;
import '../../../core/storage/session_storage.dart';
import '../../../core/storage/session_storage_provider.dart';
import '../../../core/utils/date_only.dart';
import '../../player/domain/entities/contact_details.dart';
import '../../player/domain/entities/player_enums.dart';
import '../domain/coach_models.dart';

/// The CV's repeatable sections, as the backend names them in the URL.
enum CoachCvSection {
  certifications('certifications'),
  experience('experience'),
  achievements('achievements'),
  socialLinks('social-links');

  const CoachCvSection(this.path);

  final String path;
}

/// Every coach-related call: the coach's own CV, public profiles, the
/// club↔coach invitations and staff memberships. One class rather than the
/// datasource/repository pair other features use — each call here is a
/// single request whose body is already the domain shape.
class CoachRepository {
  CoachRepository(this._client, this._storage, this._ref);

  final ApiClient _client;
  final SessionStorage _storage;
  final Ref _ref;

  Map<String, String> _bearer(String token) => {
    'Authorization': 'Bearer $token',
  };

  Future<T> _authorized<T>(Future<T> Function(String token) call) =>
      runAuthorized(_ref, _storage, call);

  dynamic _decode(http.Response response, {Set<int> ok = const {200, 201}}) {
    if (!ok.contains(response.statusCode)) {
      throw apiExceptionFromResponse(response);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  CoachProfile _profile(http.Response response) =>
      CoachProfile.fromJson(_decode(response) as Map<String, dynamic>);

  // ------------------------------------------------------------ own CV

  Future<CoachProfile> getMyProfile() => _authorized(
    (t) async =>
        _profile(await _client.get('/coaches/me', headers: _bearer(t))),
  );

  Future<CoachProfile> updateMyProfile({
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
  }) => _authorized(
    (t) async => _profile(
      await _client.patch(
        '/coaches/me',
        headers: _bearer(t),
        body: {
          'firstName': ?firstName,
          'lastName': ?lastName,
          'dateOfBirth': ?(dateOfBirth == null
              ? null
              : dateOnlyIso(dateOfBirth)),
          'nationality': ?nationality,
          'country': ?country,
          'city': ?city,
          'sport': ?sport,
          'headline': ?headline,
          'yearsOfExperience': ?yearsOfExperience,
          'bio': ?bio,
          'education': ?education,
          'specialties': ?specialties,
          'preferredFormations': ?preferredFormations,
          'languages': ?languages,
          if (contact != null)
            'contact': {
              'phone': contact.phone ?? '',
              'whatsapp': contact.whatsapp ?? '',
              'email': ?contact.email,
            },
        },
      ),
    ),
  );

  Future<CoachProfile> setVisibility(ProfileVisibility visibility) =>
      _authorized(
        (t) async => _profile(
          await _client.patch(
            '/coaches/me/visibility',
            headers: _bearer(t),
            body: {'visibility': visibility.wireValue},
          ),
        ),
      );

  Future<CoachProfile> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) => _authorized(
    (t) async => _profile(
      await _client.postMultipart(
        '/coaches/me/profile-photo',
        headers: _bearer(t),
        fileField: 'file',
        fileBytes: bytes,
        filename: filename,
      ),
    ),
  );

  Future<CoachProfile> uploadMedia({
    required List<int> bytes,
    required String filename,
    required PlayerMediaType type,
  }) => _authorized(
    (t) async => _profile(
      await _client.postMultipart(
        '/coaches/me/media',
        headers: _bearer(t),
        fileField: 'file',
        fileBytes: bytes,
        filename: filename,
        fields: {'type': type.wireValue},
      ),
    ),
  );

  Future<CoachProfile> deleteMedia(String id) => _authorized(
    (t) async => _profile(
      await _client.delete('/coaches/me/media/$id', headers: _bearer(t)),
    ),
  );

  Future<CoachProfile> addEntry(
    CoachCvSection section,
    Map<String, dynamic> body,
  ) => _authorized(
    (t) async => _profile(
      await _client.post(
        '/coaches/me/${section.path}',
        headers: _bearer(t),
        body: body,
      ),
    ),
  );

  Future<CoachProfile> updateEntry(
    CoachCvSection section,
    String id,
    Map<String, dynamic> body,
  ) => _authorized(
    (t) async => _profile(
      await _client.patch(
        '/coaches/me/${section.path}/$id',
        headers: _bearer(t),
        body: body,
      ),
    ),
  );

  Future<CoachProfile> removeEntry(CoachCvSection section, String id) =>
      _authorized(
        (t) async => _profile(
          await _client.delete(
            '/coaches/me/${section.path}/$id',
            headers: _bearer(t),
          ),
        ),
      );

  // ------------------------------------------------------------ public

  Future<CoachProfile> getPublicProfile(String id) async =>
      _profile(await _client.get('/coaches/$id'));

  Future<List<CoachSummary>> searchCoaches({
    String? search,
    int page = 1,
  }) async {
    final query = Uri(
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': '$page',
      },
    ).query;
    final json =
        _decode(await _client.get('/coaches?$query')) as Map<String, dynamic>;
    return [
      for (final item in json['items'] as List<dynamic>)
        CoachSummary.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<CoachSummary>> clubStaffPublic(String clubProfileId) async {
    final json =
        _decode(await _client.get('/memberships/clubs/$clubProfileId/coaches'))
            as Map<String, dynamic>;
    return [
      for (final item in json['items'] as List<dynamic>)
        if (item != null) CoachSummary.fromJson(item as Map<String, dynamic>),
    ];
  }

  // ---------------------------------------------------- memberships

  Future<List<CoachClubMembership>> myClubs() => _authorized((t) async {
    final json =
        _decode(await _client.get('/coaches/me/clubs', headers: _bearer(t)))
            as Map<String, dynamic>;
    return [
      for (final item in json['items'] as List<dynamic>)
        CoachClubMembership.fromJson(item as Map<String, dynamic>),
    ];
  });

  Future<void> leaveClub(String membershipId) => _authorized((t) async {
    _decode(
      await _client.delete(
        '/coaches/me/clubs/$membershipId',
        headers: _bearer(t),
      ),
      ok: const {200, 204},
    );
  });

  Future<List<StaffMember>> clubStaff() => _authorized((t) async {
    final json =
        _decode(await _client.get('/club/coaches', headers: _bearer(t)))
            as Map<String, dynamic>;
    return [
      for (final item in json['items'] as List<dynamic>)
        StaffMember.fromJson(item as Map<String, dynamic>),
    ];
  });

  Future<StaffMember> setPermissions(
    String membershipId,
    List<CoachPermission> permissions,
  ) => _authorized(
    (t) async => StaffMember.fromJson(
      _decode(
            await _client.patch(
              '/club/coaches/$membershipId/permissions',
              headers: _bearer(t),
              body: {
                'permissions': [for (final p in permissions) p.wireValue],
              },
            ),
          )
          as Map<String, dynamic>,
    ),
  );

  Future<void> removeCoach(String membershipId) => _authorized((t) async {
    _decode(
      await _client.delete('/club/coaches/$membershipId', headers: _bearer(t)),
      ok: const {200, 204},
    );
  });

  // ------------------------------------------------------ invitations

  Future<List<CoachInvitation>> invitations({required bool received}) =>
      _authorized((t) async {
        final json =
            _decode(
                  await _client.get(
                    '/coach-invitations/${received ? 'received' : 'sent'}',
                    headers: _bearer(t),
                  ),
                )
                as Map<String, dynamic>;
        return [
          for (final item in json['items'] as List<dynamic>)
            CoachInvitation.fromJson(item as Map<String, dynamic>),
        ];
      });

  Future<int> pendingReceivedCount() => _authorized((t) async {
    final json =
        _decode(
              await _client.get(
                '/coach-invitations/summary',
                headers: _bearer(t),
              ),
            )
            as Map<String, dynamic>;
    return (json['pendingReceived'] as num?)?.toInt() ?? 0;
  });

  /// A club inviting a coach by code (`COA-…`).
  Future<void> inviteCoach(String code, {String? message}) =>
      _authorized((t) async {
        _decode(
          await _client.post(
            '/coach-invitations/club-to-coach',
            headers: _bearer(t),
            body: {'coachCode': code.trim(), 'message': ?message},
          ),
        );
      });

  /// A coach asking to join a club by its code (`CLB-…`).
  Future<void> requestToJoinClub(String code, {String? message}) =>
      _authorized((t) async {
        _decode(
          await _client.post(
            '/coach-invitations/coach-to-club',
            headers: _bearer(t),
            body: {'clubCode': code.trim(), 'message': ?message},
          ),
        );
      });

  Future<void> respond(String id, String action) => _authorized((t) async {
    _decode(
      await _client.post('/coach-invitations/$id/$action', headers: _bearer(t)),
    );
  });
}

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => CoachRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
