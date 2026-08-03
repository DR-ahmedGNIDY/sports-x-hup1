import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository_impl.dart';
import '../domain/entities/lookup_option.dart';

final sportsProvider = FutureProvider<List<LookupOption>>(
  (ref) => ref.watch(playerRepositoryProvider).getSports(),
);

final countriesProvider = FutureProvider<List<LookupOption>>(
  (ref) => ref.watch(playerRepositoryProvider).getCountries(),
);
