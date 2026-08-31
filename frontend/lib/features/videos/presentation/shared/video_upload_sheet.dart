import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/mobile/app_sheet.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/my_videos_controller.dart';
import '../../application/skill_categories_provider.dart';
import '../../domain/entities/video.dart';

/// Client-side safety net matching the backend's `VIDEO_SIZE_LIMIT_BYTES`
/// (`upload.config.ts`) — rejecting an oversized file here avoids reading
/// it fully into memory for an upload attempt that Multer would reject
/// anyway once it reaches the server.
const int _kMaxVideoBytes = 50 * 1024 * 1024;

/// Bottom sheet for uploading a new Skills video: file picker, category
/// dropdown (server categories for [sport], excluding the synthetic
/// "All"), a Public/Private segmented control defaulting to Private, and
/// an upload button with its own progress state.
class VideoUploadSheet extends ConsumerStatefulWidget {
  const VideoUploadSheet({super.key, required this.sport});

  final String sport;

  static Future<void> show(BuildContext context, {required String sport}) {
    return AppSheet.show<void>(
      context: context,
      backgroundColor: AppColors.profileSurface,
      builder: (context) => VideoUploadSheet(sport: sport),
    );
  }

  @override
  ConsumerState<VideoUploadSheet> createState() => _VideoUploadSheetState();
}

class _VideoUploadSheetState extends ConsumerState<VideoUploadSheet> {
  PlatformFile? _file;
  String? _category;
  VideoVisibility _visibility = VideoVisibility.private;
  bool _uploading = false;
  String? _error;
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true, type: FileType.video);
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.length > _kMaxVideoBytes) {
      if (!mounted) return;
      setState(() {
        _file = null;
        _error = AppLocalizations.of(
          context,
        )!.videoUploadTooLargeError(_kMaxVideoBytes ~/ (1024 * 1024));
      });
      return;
    }
    setState(() {
      _file = file;
      _error = null;
    });
  }

  Future<void> _upload() async {
    final file = _file;
    final category = _category;
    if (file == null || file.bytes == null || category == null) {
      setState(() => _error = AppLocalizations.of(context)!.videoUploadMissingFieldsError);
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref
          .read(myVideosControllerProvider.notifier)
          .upload(
            bytes: file.bytes!,
            filename: file.name,
            category: category,
            visibility: _visibility,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(skillCategoriesProvider(widget.sport));
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.videoUploadTitle,
            style: const TextStyle(
              color: AppColors.profileText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickFile,
            icon: const Icon(Icons.video_file_outlined),
            label: Text(_file == null ? l10n.videoChooseFileLabel : _file!.name),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            enabled: !_uploading,
            maxLength: 100,
            decoration: InputDecoration(labelText: l10n.videoTitleLabel),
          ),
          categoriesAsync.when(
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.videoCategoryLabel),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: _uploading ? null : (value) => setState(() => _category = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(
              l10n.videoCategoriesLoadError,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<VideoVisibility>(
            segments: [
              ButtonSegment(
                value: VideoVisibility.private,
                label: Text(l10n.videoVisibilityPrivate),
                icon: const Icon(Icons.lock_outline),
              ),
              ButtonSegment(
                value: VideoVisibility.public,
                label: Text(l10n.videoVisibilityPublic),
                icon: const Icon(Icons.public),
              ),
            ],
            selected: {_visibility},
            onSelectionChanged: _uploading
                ? null
                : (selection) => setState(() => _visibility = selection.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _uploading ? null : _upload,
            child: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : Text(l10n.videoUploadButtonLabel),
          ),
        ],
      ),
    );
  }
}
