import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/entities/user_role.dart';
import '../application/coach_providers.dart';

/// Wraps a club screen (players, calendar, player invitations, club
/// profile) that a coach reaches on a club's behalf.
///
/// For a coach it holds the screen back until the active club is resolved —
/// the screen's first request must already carry `X-Club-Id`, or it would
/// meet a 403 — and shows a way to a club when the coach has none. Anyone
/// else gets [child] untouched.
class ClubContextGate extends ConsumerWidget {
  const ClubContextGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(
      sessionControllerProvider.select((s) => s.user?.role),
    );
    if (role != UserRole.coach) return child;

    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(activeClubProvider)
        .when(
          // Keyed on the club so switching rebuilds the screen from scratch
          // rather than reusing state fetched for the previous club.
          data: (active) => active == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 48),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.coachNoClubsYet, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context.go('/coach/clubs'),
                          child: Text(l10n.coachMyClubsTitle),
                        ),
                      ],
                    ),
                  ),
                )
              : KeyedSubtree(key: ValueKey(active.membershipId), child: child),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(myCoachClubsProvider),
              child: Text(l10n.retryButtonLabel),
            ),
          ),
        );
  }
}

/// The club a coach is working for, with a switch — shown at the top of
/// the coach's sidebar and home. Nothing for other roles or with no club.
class ActiveClubSwitcher extends ConsumerWidget {
  const ActiveClubSwitcher({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final clubs = ref.watch(myCoachClubsProvider).valueOrNull ?? const [];
    final active = ref.watch(activeClubProvider).valueOrNull;
    if (active == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: l10n.coachSwitchToClub,
      enabled: clubs.length > 1,
      onSelected: (membershipId) {
        final chosen = clubs.firstWhere((m) => m.membershipId == membershipId);
        ref.read(activeClubProvider.notifier).select(chosen);
      },
      itemBuilder: (_) => [
        for (final m in clubs)
          CheckedPopupMenuItem(
            value: m.membershipId,
            checked: m.membershipId == active.membershipId,
            child: Text(m.club?.name ?? l10n.coachUnnamedClub),
          ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: dense ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                active.club?.name ?? l10n.coachUnnamedClub,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (clubs.length > 1) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
