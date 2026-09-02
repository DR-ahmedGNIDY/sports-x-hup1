import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../invitations/presentation/shared/club_members_section.dart';
import '../../../invitations/presentation/shared/request_to_join_button.dart';
import '../../application/public_club_profile_provider.dart';
import '../shared/club_profile_view.dart';

class PublicClubProfilePageMobile extends ConsumerWidget {
  const PublicClubProfilePageMobile({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicClubProfileProvider(clubId));

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClubProfileView(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              RequestToJoinButton(club: profile),
              const SizedBox(height: AppSpacing.xl),
              ClubMembersSection(clubId: clubId),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: 'This club profile is not available.',
          onRetry: () => ref.invalidate(publicClubProfileProvider(clubId)),
        ),
      ),
    );
  }
}
