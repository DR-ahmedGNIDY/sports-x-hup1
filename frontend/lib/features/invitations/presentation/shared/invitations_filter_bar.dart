import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../../domain/entities/invitation.dart';
import 'invitation_labels.dart';

/// Received/Sent, and the status filter for whichever is showing.
///
/// The status filter is applied by the server, not by hiding rows that are
/// already loaded — the lists are paginated, so a client-side filter would
/// silently mean "matching rows on this page" rather than "matching rows".
class InvitationsFilterBar extends ConsumerWidget {
  const InvitationsFilterBar({
    super.key,
    required this.kind,
    required this.onKindChanged,
  });

  final InvitationsListKind kind;
  final ValueChanged<InvitationsListKind> onKindChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(invitationsSummaryProvider).value;
    final controller = ref.watch(invitationsListProvider(kind).notifier);
    final selectedStatus = controller.statusFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<InvitationsListKind>(
          segments: [
            ButtonSegment(
              value: InvitationsListKind.received,
              label: Text(_withCount(l10n.invitationsReceivedTab, summary?.pendingReceived)),
              icon: const Icon(Icons.inbox_outlined),
            ),
            ButtonSegment(
              value: InvitationsListKind.sent,
              label: Text(_withCount(l10n.invitationsSentTab, summary?.pendingSent)),
              icon: const Icon(Icons.outbox_outlined),
            ),
          ],
          selected: {kind},
          onSelectionChanged: (selection) {
            AppHaptics.selection();
            onKindChanged(selection.first);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // `null` is "every status", which is also the initial state —
              // an inbox opens showing everything rather than making the
              // viewer pick a filter before it shows them anything.
              _StatusChip(
                label: l10n.anyOption,
                selected: selectedStatus == null,
                onSelected: () => controller.applyStatus(null),
              ),
              for (final status in InvitationStatus.values) ...[
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(
                  label: invitationStatusLabel(l10n, status),
                  selected: selectedStatus == status,
                  onSelected: () => controller.applyStatus(status),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The badge is the count of *pending* invitations, which is the only
  /// number that means "there is something to do here" — a total would
  /// keep counting invitations that were answered months ago.
  String _withCount(String label, int? count) =>
      (count == null || count == 0) ? label : '$label ($count)';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        AppHaptics.selection();
        onSelected();
      },
    );
  }
}
