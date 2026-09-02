import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/public_code.dart';

/// The bottom sheet behind both "invite by player code" and "join by club
/// code": a field, a submit, and whatever the resolved code turned out to
/// be.
///
/// The lookup is a deliberate step of its own rather than sending blind on
/// the typed code. A public code is six digits with no redundancy, and
/// seeing the name it belongs to is the only thing standing between a typo
/// and an invitation to a stranger.
///
/// The two sheets differ only in their wording and in what a result looks
/// like, which is why [resultBuilder] is the seam: everything above it —
/// normalizing, submitting on enter, and *not* looking anyone up on every
/// keystroke — is the same problem in both directions.
Future<void> showCodeLookupSheet(
  BuildContext context, {
  required String Function(AppLocalizations) titleOf,
  required String Function(AppLocalizations) labelOf,
  required String Function(AppLocalizations) hintOf,
  required Widget Function(String code) resultBuilder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      // Clears the on-screen keyboard, which otherwise covers the field
      // being typed into.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _CodeLookupSheet(
        titleOf: titleOf,
        labelOf: labelOf,
        hintOf: hintOf,
        resultBuilder: resultBuilder,
      ),
    ),
  );
}

class _CodeLookupSheet extends StatefulWidget {
  const _CodeLookupSheet({
    required this.titleOf,
    required this.labelOf,
    required this.hintOf,
    required this.resultBuilder,
  });

  final String Function(AppLocalizations) titleOf;
  final String Function(AppLocalizations) labelOf;
  final String Function(AppLocalizations) hintOf;
  final Widget Function(String code) resultBuilder;

  @override
  State<_CodeLookupSheet> createState() => _CodeLookupSheetState();
}

class _CodeLookupSheetState extends State<_CodeLookupSheet> {
  final _controller = TextEditingController();

  /// The code actually submitted, which is not the same as what is in the
  /// field: resolving on every keystroke would spend the backend's tight
  /// per-minute lookup budget on prefixes of a code.
  String? _submitted;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.titleOf(l10n),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: widget.labelOf(l10n),
              hintText: widget.hintOf(l10n),
              suffixIcon: IconButton(
                tooltip: l10n.inviteByCodeLookUpLabel,
                icon: const Icon(Icons.search),
                onPressed: _submit,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_submitted case final code?) widget.resultBuilder(code),
        ],
      ),
    );
  }

  void _submit() {
    final code = normalizePublicCode(_controller.text);
    setState(() => _submitted = code.isEmpty ? null : code);
  }
}

/// The shared error branch for both lookups: an unknown code and a code
/// belonging to someone who cannot be shown read identically on purpose —
/// distinguishing them would turn either sheet into a way to test whether a
/// given code exists.
class CodeLookupError extends StatelessWidget {
  const CodeLookupError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
