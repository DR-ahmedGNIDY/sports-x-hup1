import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/auth/domain/entities/user_role.dart';
import 'package:sport_x_hub/features/coach/domain/coach_models.dart';

void main() {
  test('COACH is a known role', () {
    expect(UserRole.fromWire('COACH'), UserRole.coach);
  });

  test('permissions parse and drop values this build does not know', () {
    expect(
      CoachPermission.listFromWire(['VIEW_SQUAD', 'CREATE_PLAYERS', 'NEW_ONE']),
      [CoachPermission.viewSquad, CoachPermission.createPlayers],
    );
  });

  test('a CV parses from the owner view', () {
    final profile = CoachProfile.fromJson({
      'id': 'c1',
      'publicCode': 'COA-000001',
      'firstName': 'Sami',
      'lastName': 'Adel',
      'headline': 'Head coach',
      'specialties': ['Youth'],
      'visibility': 'PRIVATE',
      'completionPercent': 40,
      'profilePhoto': {'secureUrl': 'https://x/p.jpg'},
      'media': [
        {'_id': 'm1', 'type': 'VIDEO', 'secureUrl': 'https://x/v.mp4'},
      ],
      'experience': [
        {'_id': 'e1', 'clubName': 'A', 'role': 'Assistant', 'startYear': 2019},
      ],
      'certifications': [
        {'_id': 'k1', 'name': 'CAF C', 'year': 2020},
      ],
      'currentClubs': [
        {'id': 'club1', 'name': 'Nadi'},
      ],
      'contact': {'phone': '123'},
    });

    expect(profile.fullName, 'Sami Adel');
    expect(profile.isPublic, isFalse);
    expect(profile.profilePhotoUrl, 'https://x/p.jpg');
    expect(profile.media.single.isVideo, isTrue);
    expect(profile.media.single.thumbnailUrl, 'https://x/v.jpg');
    expect(profile.experience.single.endYear, isNull);
    expect(profile.certifications.single.name, 'CAF C');
    expect(profile.currentClubs.single.name, 'Nadi');
    expect(profile.contact.phone, '123');
  });

  test('a club membership knows what the coach may do there', () {
    final m = CoachClubMembership.fromJson({
      'membershipId': 'm1',
      'club': {'id': 'club1', 'name': 'Nadi'},
      'permissions': ['VIEW_SQUAD', 'MANAGE_CALENDAR'],
    });
    expect(m.can(CoachPermission.manageCalendar), isTrue);
    expect(m.can(CoachPermission.createPlayers), isFalse);
  });
}
