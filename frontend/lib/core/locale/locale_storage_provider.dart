import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_storage.dart';

/// Overridden in `main()` once `SharedPreferences.getInstance()` resolves —
/// see the `ProviderScope(overrides: ...)` call there. Same pattern as
/// sessionStorageProvider (core/storage/session_storage_provider.dart).
final localeStorageProvider = Provider<LocaleStorage>(
  (ref) => throw UnimplementedError('localeStorageProvider must be overridden in main()'),
);
