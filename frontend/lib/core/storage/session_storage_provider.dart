import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_storage.dart';

/// Overridden in `main()` once `SharedPreferences.getInstance()` resolves —
/// see the `ProviderScope(overrides: ...)` call there.
final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => throw UnimplementedError('sessionStorageProvider must be overridden in main()'),
);
