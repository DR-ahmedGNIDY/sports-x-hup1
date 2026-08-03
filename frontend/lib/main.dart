import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_storage.dart';
import 'core/storage/session_storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWithValue(SessionStorage(prefs)),
      ],
      child: const SportXHubApp(),
    ),
  );
}

class SportXHubApp extends ConsumerWidget {
  const SportXHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Sport X Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
