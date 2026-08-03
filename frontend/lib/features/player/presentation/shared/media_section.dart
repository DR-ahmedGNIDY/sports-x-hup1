import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_media.dart';

/// Photo/video gallery — upload via Cloudinary, delete, and mark a photo
/// as the profile photo.
class MediaSection extends ConsumerStatefulWidget {
  const MediaSection({super.key});

  @override
  ConsumerState<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends ConsumerState<MediaSection> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload(PlayerMediaType type) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: type == PlayerMediaType.photo ? FileType.image : FileType.video,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref
          .read(playerProfileControllerProvider.notifier)
          .uploadMedia(
            bytes: file.bytes!,
            filename: file.name,
            type: type,
            isProfilePhoto: type == PlayerMediaType.photo,
          );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ref.read(playerProfileControllerProvider.notifier).deleteMedia(id);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = ref.watch(playerProfileControllerProvider).value?.media ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Photos & Videos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (media.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: media.map((item) => _MediaTile(item: item, onDelete: _delete)).toList(),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploading ? null : () => _pickAndUpload(PlayerMediaType.photo),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add photo'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _uploading ? null : () => _pickAndUpload(PlayerMediaType.video),
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Add video'),
            ),
            if (_uploading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item, required this.onDelete});

  final PlayerMedia item;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.slate,
            borderRadius: BorderRadius.circular(8),
            border: item.isProfilePhoto
                ? Border.all(color: AppColors.brandBlue, width: 2)
                : null,
            image: item.type == PlayerMediaType.photo
                ? DecorationImage(image: NetworkImage(item.secureUrl), fit: BoxFit.cover)
                : null,
          ),
          child: item.type == PlayerMediaType.video
              ? const Center(
                  child: Icon(Icons.play_circle_outline, color: AppColors.white, size: 32),
                )
              : null,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => onDelete(item.id),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.error,
              child: Icon(Icons.close, size: 14, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
