import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment configuration loaded from `.env` (see
/// `.env.example` for the required keys). Call [Env.load] once in `main()`
/// before `runApp`.
abstract final class Env {
  /// Loads `.env`, and never throws.
  ///
  /// On web this file is fetched over HTTP — it is rewritten from container
  /// environment on every start (see `docker-entrypoint.sh`), so it cannot be
  /// compiled in. `main()` awaits this before `runApp`, which means that
  /// before this guard existed a network hiccup did not degrade the app: it
  /// stopped it from starting at all, with a blank screen and an uncaught
  /// exception. That was exactly what happened with the service worker
  /// offline until it learned to serve this file from cache.
  ///
  /// Falling through to the defaults below is the right failure: the app
  /// starts, and if the API base URL really was needed it fails later at a
  /// request, where the app has error states to show.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (error) {
      debugPrint('Env: falling back to defaults — .env unavailable ($error)');
      // dotenv throws on every read until it has been initialized once, so
      // seeding it empty is what makes the fallbacks below reachable.
      dotenv.loadFromString(envString: '', isOptional: true);
    }
  }

  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000');

  static String get appEnv => dotenv.get('APP_ENV', fallback: 'development');
}
