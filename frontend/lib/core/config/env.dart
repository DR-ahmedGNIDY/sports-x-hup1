import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment configuration loaded from `.env` (see
/// `.env.example` for the required keys). Call [Env.load] once in `main()`
/// before `runApp`.
abstract final class Env {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000');

  static String get appEnv => dotenv.get('APP_ENV', fallback: 'development');
}
