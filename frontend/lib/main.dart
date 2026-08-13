import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/locale/locale_provider.dart';
import 'core/locale/locale_storage.dart';
import 'core/locale/locale_storage_provider.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_storage.dart';
import 'core/storage/session_storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/application/session_controller.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWithValue(SessionStorage(prefs)),
        localeStorageProvider.overrideWithValue(LocaleStorage(prefs)),
      ],
      child: const SportXHubApp(),
    ),
  );
}

class SportXHubApp extends ConsumerStatefulWidget {
  const SportXHubApp({super.key});

  @override
  ConsumerState<SportXHubApp> createState() => _SportXHubAppState();
}

class _SportXHubAppState extends ConsumerState<SportXHubApp> {
  @override
  void initState() {
    super.initState();
    // Triggered once here (app root), not just from SplashPage, so a cold
    // load that lands directly on a route Splash never mounts for — e.g. a
    // shared /players/:id link, which is intentionally exempt from the
    // splash redirect — still restores the session. Without this, a Club
    // opening a shared profile link in a fresh tab would never see its
    // Save/Contact actions despite holding a valid stored token.
    Future.microtask(
      () => ref.read(sessionControllerProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Sport X Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => Directionality(
        textDirection: locale == arabicLocale
            ? TextDirection.ltr
            : TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
