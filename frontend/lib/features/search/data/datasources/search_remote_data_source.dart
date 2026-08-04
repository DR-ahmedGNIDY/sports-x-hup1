import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;
import '../../domain/entities/player_search_filters.dart';

/// Search is a public endpoint (no auth) — filters are sent as query params.
class SearchRemoteDataSource {
  SearchRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> search(PlayerSearchFilters filters) async {
    final query = <String, String>{
      if (filters.country != null) 'country': filters.country!,
      if (filters.minAge != null) 'minAge': '${filters.minAge}',
      if (filters.maxAge != null) 'maxAge': '${filters.maxAge}',
      if (filters.position != null) 'position': filters.position!,
      if (filters.minHeight != null) 'minHeight': '${filters.minHeight}',
      if (filters.maxHeight != null) 'maxHeight': '${filters.maxHeight}',
      if (filters.weight != null) 'weight': '${filters.weight}',
      if (filters.preferredFoot != null) 'preferredFoot': filters.preferredFoot!.wireValue,
      if (filters.sport != null) 'sport': filters.sport!,
      'page': '${filters.page}',
    };
    final queryString = Uri(queryParameters: query).query;
    final response = await _client.get('/players?$queryString');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>(
  (ref) => SearchRemoteDataSource(ref.watch(apiClientProvider)),
);
