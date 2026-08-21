import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/video_repository_impl.dart';
import '../../domain/entities/video_comment.dart';
import 'comment_tile.dart';

/// Opens the comments sheet for [videoId]. [onCommentCountChanged] lets the
/// caller's own list controller (My Videos / Public Videos / Community
/// feed) patch its local comment count without this sheet knowing which
/// kind of list it was opened from.
Future<void> showVideoCommentsSheet(
  BuildContext context, {
  required String videoId,
  void Function(int delta)? onCommentCountChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.profileColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _VideoCommentsSheet(
      videoId: videoId,
      onCommentCountChanged: onCommentCountChanged,
    ),
  );
}

class _VideoCommentsSheet extends ConsumerStatefulWidget {
  const _VideoCommentsSheet({required this.videoId, this.onCommentCountChanged});

  final String videoId;
  final void Function(int delta)? onCommentCountChanged;

  @override
  ConsumerState<_VideoCommentsSheet> createState() => _VideoCommentsSheetState();
}

class _VideoCommentsSheetState extends ConsumerState<_VideoCommentsSheet> {
  final _controller = TextEditingController();
  List<VideoComment> _comments = [];
  int _page = 1;
  bool _hasNextPage = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _sending = false;
  String? _error;

  /// Set only when the initial [_load] fails — distinct from [_error] (used
  /// for send/delete/load-more action failures shown as an inline banner)
  /// so a failed first load can show the full [ErrorState] + Retry instead
  /// of an empty list with a stray error line above it.
  String? _initialLoadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _initialLoadError = null;
    });
    try {
      final page = await ref.read(videoRepositoryProvider).listComments(widget.videoId);
      setState(() {
        _comments = page.items;
        _page = page.page;
        _hasNextPage = page.hasNextPage;
        _loading = false;
      });
    } on AppException catch (e) {
      setState(() {
        _initialLoadError = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNextPage) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(videoRepositoryProvider)
          .listComments(widget.videoId, page: _page + 1);
      setState(() {
        _comments = [..._comments, ...page.items];
        _page = page.page;
        _hasNextPage = page.hasNextPage;
      });
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await ref.read(videoRepositoryProvider).addComment(widget.videoId, text);
      setState(() {
        _comments = [comment, ..._comments];
        _controller.clear();
      });
      widget.onCommentCountChanged?.call(1);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDelete(VideoComment comment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.videoCommentDeleteTitle),
        content: Text(l10n.videoCommentDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteLabel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _delete(comment);
    }
  }

  Future<void> _delete(VideoComment comment) async {
    try {
      await ref.read(videoRepositoryProvider).deleteComment(widget.videoId, comment.id);
      setState(() => _comments = _comments.where((c) => c.id != comment.id).toList());
      widget.onCommentCountChanged?.call(-1);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final colors = context.profileColors;
    final hairline = colors.borderOnSurface.withValues(alpha: 0.12);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderOnSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.videoCommentsTitle,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: hairline),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _initialLoadError != null
                  ? ErrorState(message: _initialLoadError, onRetry: _load)
                  : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EmptyStateIllustration(variant: EmptyStateVariant.noData),
                          const SizedBox(height: 12),
                          Text(
                            l10n.videoCommentsEmptyState,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _comments.length + (_hasNextPage ? 1 : 0),
                      separatorBuilder: (_, _) => Divider(height: 20, color: hairline),
                      itemBuilder: (context, index) {
                        if (index >= _comments.length) {
                          return Center(
                            child: _loadingMore
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : TextButton(
                                    onPressed: _loadMore,
                                    child: Text(l10n.videoCommentsLoadMore),
                                  ),
                          );
                        }
                        final comment = _comments[index];
                        return CommentTile(
                          key: ValueKey(comment.id),
                          comment: comment,
                          onDelete: comment.isMine ? () => _confirmDelete(comment) : null,
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        hintText: l10n.videoCommentHint,
                        hintStyle: TextStyle(color: colors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.send, color: colors.accent),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
