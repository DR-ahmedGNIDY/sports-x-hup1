import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bridges a Riverpod provider to go_router's `refreshListenable` so the
/// router re-evaluates `redirect` whenever session state changes (e.g.
/// right after login/logout), not just on the next navigation attempt.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref, ProviderListenable<Object?> provider) {
    ref.listen(provider, (_, _) => notifyListeners());
  }
}
