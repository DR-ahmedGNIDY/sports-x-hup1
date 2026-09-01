// Regression test for a blank-screen failure found while verifying the
// offline service worker in M7.
//
// `main()` awaits `Env.load()` before `runApp`, and on web that file is
// fetched over HTTP — it is rewritten from container environment on every
// start, so it cannot be compiled in. When it was unreachable, `load()`
// threw, `main()` never reached `runApp`, and the app rendered nothing with
// an uncaught exception in the console.
//
// A config file the app cannot fetch should cost the app its configuration,
// not its ability to start.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_x_hub/core/config/env.dart';

void main() {
  setUp(dotenv.clean);

  test('a missing .env does not stop the app from starting', () async {
    // No asset bundle is registered in a plain test binding, so this is the
    // same failure shape as an offline fetch: load() cannot find the file.
    await expectLater(Env.load(), completes);
  });

  test('and the defaults are readable afterwards', () async {
    await Env.load();

    // dotenv throws NotInitializedError on every read until it has been
    // initialized once, so "it didn't throw" is not enough — the fallbacks
    // have to actually be reachable.
    expect(Env.apiBaseUrl, isNotEmpty);
    expect(Env.appEnv, 'development');
  });

  test('a real .env still wins over the defaults', () {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test\nAPP_ENV=production',
    );

    expect(Env.apiBaseUrl, 'https://api.example.test');
    expect(Env.appEnv, 'production');
  });
}
