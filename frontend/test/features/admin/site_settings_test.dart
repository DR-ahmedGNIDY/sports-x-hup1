import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/admin/domain/entities/site_settings.dart';

void main() {
  group('SiteSettings', () {
    test('reads the empty defaults the server returns before a first save', () {
      final settings = SiteSettings.fromJson(const {'updatedAt': null});

      expect(settings.facebookUrl, '');
      expect(settings.phones, isEmpty);
    });

    test('round-trips every field the admin form sends', () {
      const original = SiteSettings(
        facebookUrl: 'https://facebook.com/sxh',
        whatsappNumber: '+201100000000',
        phones: [SitePhone(label: 'Support', number: '+201000000000')],
        email: 'info@sportxhup.com',
        googlePlayUrl: 'https://play.google.com/store/apps/details?id=x',
      );

      final copy = SiteSettings.fromJson(original.toJson());

      expect(copy.toJson(), original.toJson());
    });
  });
}
