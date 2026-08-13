import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import '../../domain/entities/player_enums.dart';

/// Dedicated profile-photo uploader — separate from the general
/// [MediaSection] gallery so "set my profile picture" is its own obvious
/// control (mirrors ClubLogoSection) instead of an implicit side effect of
/// adding a gallery photo. Uploads immediately on pick, like the gallery
/// and the club logo — there's nothing to "save" here.
class ProfilePhotoSection extends ConsumerStatefulWidget {
  const ProfilePhotoSection({super.key});

  @override
  ConsumerState<ProfilePhotoSection> createState() => _ProfilePhotoSectionState();
}

class _ProfilePhotoSectionState extends ConsumerState<ProfilePhotoSection> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(withData: true, type: FileType.image);
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
            type: PlayerMediaType.photo,
            isProfilePhoto: true,
          );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = ref.watch(playerProfileControllerProvider).value?.profilePhoto?.secureUrl;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profilePhotoSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.slate,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 40, color: AppColors.greyLight)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _uploading
                      ? l10n.uploadingLabel
                      : (photoUrl != null ? l10n.changePhotoLabel : l10n.uploadPhotoLabel),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}
