import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/data/models/player_search_result_model.dart';
import '../../domain/entities/player_search_filters.dart';
import '../../domain/entities/player_search_page.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<PlayerSearchPage> search(PlayerSearchFilters filters) async {
    final json = await _remote.search(filters);
    final items = (json['items'] as List<dynamic>)
        .map((e) => PlayerSearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PlayerSearchPage(
      items: items,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(searchRemoteDataSourceProvider)),
);
