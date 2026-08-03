import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/achievement.dart';

/// Simple list of achievements (title, year, description) with add/edit/
/// delete — mirrors the "simple list" scope from the roadmap (no ranking,
/// categories, or attachments).
class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Achievement? existing}) {
    return showDialog(
      context: context,
      builder: (_) => _AchievementDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements =
        ref.watch(playerProfileControllerProvider).value?.achievements ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              tooltip: 'Add achievement',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _openForm(context, ref),
            ),
          ],
        ),
        if (achievements.isEmpty) const Text('No achievements added yet.'),
        for (final achievement in achievements)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${achievement.title} (${achievement.year})'),
            subtitle: achievement.description != null
                ? Text(achievement.description!)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openForm(context, ref, existing: achievement),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(playerProfileControllerProvider.notifier)
                      .deleteAchievement(achievement.id),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AchievementDialog extends ConsumerStatefulWidget {
  const _AchievementDialog({this.existing});

  final Achievement? existing;

  @override
  ConsumerState<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends ConsumerState<_AchievementDialog> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _year = TextEditingController(
    text: widget.existing?.year.toString() ?? '',
  );
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final year = int.tryParse(_year.text.trim());
    if (_title.text.trim().isEmpty || year == null) {
      setState(() => _error = 'Enter a title and a valid year.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(playerProfileControllerProvider.notifier);
      if (widget.existing != null) {
        await notifier.updateAchievement(
          widget.existing!.id,
          title: _title.text.trim(),
          year: year,
          description: _description.text.trim(),
        );
      } else {
        await notifier.addAchievement(
          title: _title.text.trim(),
          year: year,
          description: _description.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit achievement' : 'Add achievement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Year'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
