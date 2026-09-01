import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'core/utils/app_scroll_behavior.dart';
import 'core/utils/breakpoints.dart';
import 'core/utils/safe_area_insets.dart';
import 'features/auth/application/session_controller.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final prefs = await SharedPreferences.getInstance();

  final sessionStorage = SessionStorage(const FlutterSecureStorage());
  // Upgrades any install still holding tokens from the previous
  // SharedPreferences-based SessionStorage — see its doc comment. A no-op
  // for every install created after this change.
  await sessionStorage.migrateFromSharedPreferences(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWithValue(sessionStorage),
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
      scrollBehavior: const AppScrollBehavior(),
      // `applyWebSafeArea` runs outermost so the injected MediaQuery is in
      // scope for the whole app, including anything Directionality wraps.
      // It's a no-op off the web — see its doc comment.
      //
      // The compact type scale is applied here rather than inside
      // `AppTheme.light`/`dark` because this is the first place with a
      // MediaQuery to measure: the theme has to know the viewport width, and
      // above MaterialApp there isn't one. Reading it here also means a
      // window resized across the breakpoint re-types the app live.
      builder: (context, child) => applyWebSafeArea(
        context: context,
        child: _WithCompactTypography(
          child: Directionality(
            textDirection: locale == arabicLocale
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child!,
          ),
        ),
      ),
    );
  }
}

/// Swaps in [AppTheme.compact]'s phone type scale below the Desktop/Mobile
/// breakpoint — the same single decision point every screen already uses to
/// fork its presentation, so the type scale can never disagree with the
/// layout it is typesetting.
class _WithCompactTypography extends StatelessWidget {
  const _WithCompactTypography({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) return child;
    return Theme(data: AppTheme.compact(Theme.of(context)), child: child);
  }
}
