import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../player/application/lookup_providers.dart';
import '../../application/home_feed_controller.dart';
import '../../data/repositories/feed_repository_impl.dart';

/// Client-side safety net matching the backend's `IMAGE_SIZE_LIMIT_BYTES`
/// (`upload.config.ts`) — same rationale as VideoUploadSheet's cap.
const int _kMaxImageBytes = 5 * 1024 * 1024;

/// Bottom sheet for publishing a Photo post to the Home feed — reachable
/// from the feed itself (Player, via [HomeFeedController.publish], so the
/// new post appears at the top immediately) and from the Club dashboard
/// (Club has no feed of its own to browse yet, just the ability to post
/// into players' feeds — see PostsService.createPost on the backend for
/// why a Club must choose a sport explicitly while a Player doesn't).
class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key, required this.role});

  final UserRole role;

  static Future<void> show(BuildContext context, {required UserRole role}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.profileSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CreatePostSheet(role: role),
    );
  }

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  PlatformFile? _file;
  String? _sport;
  bool _posting = false;
  String? _error;
  final _captionController = TextEditingController();

  bool get _isClub => widget.role == UserRole.club;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true, type: FileType.image);
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.length > _kMaxImageBytes) {
      if (!mounted) return;
      setState(() {
        _file = null;
        _error = AppLocalizations.of(context)!.homeFeedPostTooLargeError(_kMaxImageBytes ~/ (1024 * 1024));
      });
      return;
    }
    setState(() {
      _file = file;
      _error = null;
    });
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context)!;
    final file = _file;
    if (file == null || file.bytes == null) {
      setState(() => _error = l10n.homeFeedPostMissingImageError);
      return;
    }
    if (_isClub && (_sport == null || _sport!.isEmpty)) {
      setState(() => _error = l10n.homeFeedPostMissingSportError);
      return;
    }
    setState(() {
      _posting = true;
      _error = null;
    });
    try {
      final caption = _captionController.text.trim().isEmpty ? null : _captionController.text.trim();
      // A Player publishes straight into their own already-loaded Home
      // feed (see HomeFeedController.publish — it prepends locally rather
      // than refetching); a Club has no Home feed controller mounted
      // here, so it goes through the repository directly instead.
      if (_isClub) {
        await ref
            .read(feedRepositoryProvider)
            .createPost(bytes: file.bytes!, filename: file.name, caption: caption, sport: _sport);
      } else {
        await ref
            .read(homeFeedControllerProvider.notifier)
            .publish(bytes: file.bytes!, filename: file.name, caption: caption);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.homeFeedPostSuccessMessage)));
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportsAsync = ref.watch(sportsProvider);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.homeFeedNewPostTitle,
            style: const TextStyle(color: AppColors.profileText, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _posting ? null : _pickFile,
            icon: const Icon(Icons.image_outlined),
            label: Text(_file == null ? l10n.homeFeedChooseImageLabel : _file!.name),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            enabled: !_posting,
            maxLength: 500,
            maxLines: 3,
            style: const TextStyle(color: AppColors.profileText),
            decoration: InputDecoration(labelText: l10n.homeFeedCaptionLabel),
          ),
          if (_isClub)
            sportsAsync.when(
              data: (options) => DropdownButtonFormField<String>(
                initialValue: _sport,
                decoration: InputDecoration(labelText: l10n.homeFeedSportLabel),
                items: options
                    .map((o) => DropdownMenuItem(value: o.name, child: Text(o.name)))
                    .toList(),
                onChanged: _posting ? null : (value) => setState(() => _sport = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : Text(l10n.homeFeedPostButtonLabel),
          ),
        ],
      ),
    );
  }
}
