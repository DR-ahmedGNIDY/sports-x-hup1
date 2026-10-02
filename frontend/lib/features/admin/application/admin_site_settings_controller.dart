import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/admin_site_settings_data_source.dart';
import '../domain/entities/site_settings.dart';

/// The website settings as the server holds them. [save] replaces the state
/// with the server's answer, so the form re-seeds from what was stored
/// (trimmed, lower-cased email) rather than from what was typed.
class AdminSiteSettingsController extends AsyncNotifier<SiteSettings> {
  @override
  Future<SiteSettings> build() =>
      ref.read(adminSiteSettingsDataSourceProvider).get();

  Future<void> save(SiteSettings settings) async {
    final saved = await ref
        .read(adminSiteSettingsDataSourceProvider)
        .save(settings);
    state = AsyncData(saved);
  }
}

final adminSiteSettingsControllerProvider =
    AsyncNotifierProvider<AdminSiteSettingsController, SiteSettings>(
      AdminSiteSettingsController.new,
    );
