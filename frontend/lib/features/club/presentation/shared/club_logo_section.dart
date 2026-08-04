import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/club_profile_controller.dart';

class ClubLogoSection extends ConsumerStatefulWidget {
  const ClubLogoSection({super.key});

  @override
  ConsumerState<ClubLogoSection> createState() => _ClubLogoSectionState();
}

class _ClubLogoSectionState extends ConsumerState<ClubLogoSection> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref
          .read(clubProfileControllerProvider.notifier)
          .uploadLogo(bytes: file.bytes!, filename: file.name);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = ref.watch(clubProfileControllerProvider).value?.logoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Club Logo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.slate,
            borderRadius: BorderRadius.circular(8),
            image: logoUrl != null
                ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                : null,
          ),
          child: logoUrl == null
              ? const Icon(Icons.shield_outlined, color: AppColors.greyLight, size: 40)
              : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: const Icon(Icons.upload_outlined),
          label: Text(_uploading ? 'Uploading…' : 'Upload logo'),
        ),
      ],
    );
  }
}
