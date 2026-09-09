import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/features/store/data/models/store_models.dart';

void main() {
  group('StoreBannerModel', () {
    test('picks the image for the viewport', () {
      final banner = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
        'mobileUrl': 'https://img/tall.jpg',
      })!;

      expect(banner.imageFor(isDesktop: true), 'https://img/wide.jpg');
      expect(banner.imageFor(isDesktop: false), 'https://img/tall.jpg');
    });

    test('falls back to the desktop crop when there is no mobile one', () {
      // The server already substitutes it, but a client that assumed a
      // separate mobile URL would render nothing if it ever stopped.
      final banner = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
      })!;

      expect(banner.imageFor(isDesktop: false), 'https://img/wide.jpg');
    });

    test('drops a banner with no desktop image rather than throwing', () {
      // The public endpoint withholds these, so one arriving means an older
      // server — fewer slides beats an unrenderable home page.
      expect(
        StoreBannerModel.fromJson({'id': 'b1', 'mobileUrl': 'https://img/m.jpg'}),
        isNull,
      );
    });

    test('resolves the description per locale, falling back to English', () {
      final bilingual = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
        'alt': {'en': 'Summer sale', 'ar': 'تخفيضات الصيف'},
      })!;
      expect(bilingual.alt(true), 'تخفيضات الصيف');
      expect(bilingual.alt(false), 'Summer sale');

      final englishOnly = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
        'alt': {'en': 'Summer sale'},
      })!;
      // A banner can go live in English and pick up its Arabic later.
      expect(englishOnly.alt(true), 'Summer sale');
    });

    test('leaves the description null when there is none', () {
      final banner = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
      })!;
      // Null, not empty: the hero hides the label entirely rather than
      // announcing an empty one to a screen reader.
      expect(banner.alt(false), isNull);
      expect(banner.alt(true), isNull);
    });

    test('carries the link path when set, and null when not', () {
      final linked = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
        'linkPath': '/c/men',
      })!;
      expect(linked.linkPath, '/c/men');

      final plain = StoreBannerModel.fromJson({
        'id': 'b1',
        'desktopUrl': 'https://img/wide.jpg',
      })!;
      expect(plain.linkPath, isNull);
    });
  });

  group('AdminBannerModel', () {
    test('keeps the two images apart, so a gap can be pointed at', () {
      final banner = AdminBannerModel.fromJson({
        'id': 'b1',
        'desktopImage': {'publicId': 'd', 'secureUrl': 'https://img/wide.jpg'},
        'sortOrder': 2,
        'isActive': true,
      });

      expect(banner.desktopUrl, 'https://img/wide.jpg');
      // The storefront view substitutes the desktop crop here; the
      // dashboard must not, or it could never say one is missing.
      expect(banner.mobileUrl, isNull);
    });

    test('explains why a banner is off the store', () {
      final noImage = AdminBannerModel.fromJson({
        'id': 'b1',
        'sortOrder': 0,
        'isActive': true,
      });
      expect(noImage.withheldReason, 'No desktop image yet');

      final switchedOff = AdminBannerModel.fromJson({
        'id': 'b2',
        'desktopImage': {'publicId': 'd', 'secureUrl': 'https://img/w.jpg'},
        'sortOrder': 0,
        'isActive': false,
      });
      expect(switchedOff.withheldReason, 'Switched off');
    });

    test('says nothing when the banner is live', () {
      final live = AdminBannerModel.fromJson({
        'id': 'b1',
        'desktopImage': {'publicId': 'd', 'secureUrl': 'https://img/w.jpg'},
        'sortOrder': 0,
        'isActive': true,
      });
      expect(live.withheldReason, isNull);
    });

    test('reports the missing image before the switch', () {
      // Both are wrong at once; the one to fix first is the upload.
      final neither = AdminBannerModel.fromJson({
        'id': 'b1',
        'sortOrder': 0,
        'isActive': false,
      });
      expect(neither.withheldReason, 'No desktop image yet');
    });
  });
}
