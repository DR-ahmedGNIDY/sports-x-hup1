import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/club_repository_impl.dart';
import '../domain/entities/club_profile.dart';

// autoDispose — same rationale as publicPlayerProfileProvider: each id is a
// one-off page visit from the Public Clubs listing, not reusable reference
// data.
final publicClubProfileProvider = FutureProvider.autoDispose.family<ClubProfile, String>(
  (ref, id) => ref.watch(clubRepositoryProvider).getById(id),
);
