import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/entities/admin_user.dart';

/// What the admin chose in [showSuspendUserDialog].
typedef SuspensionChoice = ({SuspensionDuration duration, String? reason});

/// Asks how long to suspend an account for, and optionally why. Returns
/// null if the admin backed out.
///
/// The term is a fixed menu rather than a date picker because that is the
/// set the backend accepts (`SuspensionDuration`), and because every term
/// except "permanent" lifts itself when it expires — an admin picking an
/// arbitrary date would imply a precision the feature does not have.
Future<SuspensionChoice?> showSuspendUserDialog(
  BuildContext context,
  AdminUser user,
) {
  return showDialog<SuspensionChoice>(
    context: context,
    builder: (context) => _SuspendUserDialog(user: user),
  );
}

class _SuspendUserDialog extends StatefulWidget {
  const _SuspendUserDialog({required this.user});

  final AdminUser user;

  @override
  State<_SuspendUserDialog> createState() => _SuspendUserDialogState();
}

class _SuspendUserDialogState extends State<_SuspendUserDialog> {
  SuspensionDuration _duration = SuspensionDuration.oneMonth;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Map<SuspensionDuration, String> _labels(AppLocalizations l10n) => {
    SuspensionDuration.oneMonth: l10n.adminSuspendOneMonth,
    SuspensionDuration.threeMonths: l10n.adminSuspendThreeMonths,
    SuspensionDuration.oneYear: l10n.adminSuspendOneYear,
    SuspensionDuration.permanent: l10n.adminSuspendPermanent,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = _labels(l10n);
    return AlertDialog(
      title: Text(l10n.adminSuspendAccountTitle),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminSuspendAccountBody(widget.user.email),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            RadioGroup<SuspensionDuration>(
              groupValue: _duration,
              onChanged: (value) => setState(() => _duration = value!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final duration in SuspensionDuration.values)
                    RadioListTile<SuspensionDuration>(
                      value: duration,
                      title: Text(labels[duration]!),
                      subtitle: duration == SuspensionDuration.permanent
                          ? Text(l10n.adminSuspendPermanentHint)
                          : null,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reasonController,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.adminSuspendReasonLabel,
                helperText: l10n.adminSuspendReasonHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.of(context).pop((
              duration: _duration,
              reason: reason.isEmpty ? null : reason,
            ));
          },
          child: Text(l10n.suspendLabel),
        ),
      ],
    );
  }
}
