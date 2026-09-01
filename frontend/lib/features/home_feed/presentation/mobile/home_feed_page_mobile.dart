import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../application/home_feed_controller.dart';
import '../shared/create_post_sheet.dart';
import '../shared/home_feed_slivers.dart';

/// The Player's Home tab: an infinite feed under the app's wordmark.
///
/// Unlike Desktop, this doesn't go through `HomeFeedBody` any more. That
/// widget supplies a Scaffold, a column cap and a floating action button —
/// all three of which the mobile shell now provides, contradicts, or (in the
/// FAB's case) would have parked on top of the bottom tab bar. Composing moved
/// to the app bar instead, which is where a phone app with a tab bar puts it.
class HomeFeedPageMobile extends ConsumerWidget {
  const HomeFeedPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffoldMobile(
      onRefresh: () => ref.read(homeFeedControllerProvider.notifier).refresh(),
      actions: [
        IconButton(
          tooltip: l10n.homeFeedNewPostTooltip,
          onPressed: () => CreatePostSheet.show(context, role: UserRole.player),
          icon: const Icon(Icons.add_a_photo_outlined),
        ),
      ],
      slivers: [
        HomeFeedSliver(
          onCreatePost: () =>
              CreatePostSheet.show(context, role: UserRole.player),
          // Full-bleed column: the cards carry small, even side gutters
          // rather than being centered inside a narrower one.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ],
    );
  }
}
