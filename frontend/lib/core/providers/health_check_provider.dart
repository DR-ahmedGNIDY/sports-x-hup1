import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Diagnostic-only provider proving the Flutter app can reach the NestJS
/// backend (`GET /health`). Not a business feature — this exists purely to
/// verify the Phase 0 foundation end-to-end, per the roadmap's acceptance
/// criteria for this phase.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final healthCheckProvider = FutureProvider<HealthStatus>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get('/health');
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  return HealthStatus(
    isOk: response.statusCode == 200 && body['status'] == 'ok',
    database: body['database'] as String? ?? 'unknown',
  );
});

class HealthStatus {
  const HealthStatus({required this.isOk, required this.database});

  final bool isOk;
  final String database;
}
