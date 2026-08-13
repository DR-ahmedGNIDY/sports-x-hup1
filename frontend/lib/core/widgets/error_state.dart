import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Friendly, reusable error state: an icon, a short message, and a Retry
/// action. Intended for `.when(error: ...)` branches of `AsyncValue`-backed
/// views, matching the visual language already used for one-off error
/// states (e.g. the video playback error in
/// `features/videos/presentation/shared/video_player_screen.dart`) and the
/// empty-state text color convention (`colorScheme`-driven, not hardcoded).
///
/// Not wired into any call site yet — this is the shared widget only.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.message});

  /// Called when the user taps the Retry button.
  final VoidCallback onRetry;

  /// Optional override for the displayed message. Defaults to a generic,
  /// localized "something went wrong" message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              message ?? l10n.genericErrorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.retryButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
