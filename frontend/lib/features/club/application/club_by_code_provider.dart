import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../invitations/domain/public_code.dart';
import '../data/repositories/club_repository_impl.dart';
import '../domain/entities/club_profile.dart';

/// `GET /clubs/by-code/:code` — the lookup behind "join by club code".
/// autoDispose, and normalized before the request for the same reasons as
/// [playerByCodeProvider]: a typed code is a one-off, and "clb-1 " must not
/// become a second cache key for a club the previous lookup already found.
final clubByCodeProvider = FutureProvider.autoDispose.family<ClubProfile, String>(
  (ref, code) => ref.watch(clubRepositoryProvider).getByCode(normalizePublicCode(code)),
);
