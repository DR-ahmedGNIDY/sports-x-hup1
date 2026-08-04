import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

/// POST /contact is a public, unauthenticated endpoint — see contact.controller.ts.
class ContactRemoteDataSource {
  ContactRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> submit({
    required String name,
    required String email,
    required String message,
  }) async {
    final response = await _client.post(
      '/contact',
      body: {'name': name, 'email': email, 'message': message},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }
}

final contactRemoteDataSourceProvider = Provider<ContactRemoteDataSource>(
  (ref) => ContactRemoteDataSource(ref.watch(apiClientProvider)),
);
