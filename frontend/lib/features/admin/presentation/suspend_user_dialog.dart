import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
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

  static const _labels = {
    SuspensionDuration.oneMonth: '1 month',
    SuspensionDuration.threeMonths: '3 months',
    SuspensionDuration.oneYear: '1 year',
    SuspensionDuration.permanent: 'Permanent',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspend account'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.user.email} will not be able to log in.',
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
                      title: Text(_labels[duration]!),
                      subtitle: duration == SuspensionDuration.permanent
                          ? const Text(
                              'Stays suspended until an admin reactivates it.',
                            )
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
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                helperText: 'Internal note — the user never sees this.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.of(context).pop((
              duration: _duration,
              reason: reason.isEmpty ? null : reason,
            ));
          },
          child: const Text('Suspend'),
        ),
      ],
    );
  }
}
