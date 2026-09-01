import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../empty_state_illustration.dart';

/// The shape every "there is nothing here" screen takes: an illustration, a
/// sentence saying what is missing, and — where there is one — the action
/// that would fix it.
///
/// The illustration already existed; what didn't was any agreement on what
/// goes around it. One screen centred a bare sentence, another added a button,
/// a third showed only text with no illustration at all. The difference
/// between "empty" and "broken" is entirely in that framing, so it stops being
/// a per-screen decision here.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.variant = EmptyStateVariant.noData,
    this.actionLabel,
    this.onAction,
  });

  /// What is missing, in a sentence. Not a title — an empty list needs an
  /// explanation more than it needs a heading.
  final String message;

  final EmptyStateVariant variant;

  /// The way out, when one exists. A filtered-empty list usually has none:
  /// offering "create one" to someone whose filter simply matched nothing is
  /// an answer to a question they didn't ask.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateIllustration(variant: variant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
