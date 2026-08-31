import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The Home feed's post composer entry point — a tappable pill (opens
/// [CreatePostSheet], the existing upload flow) styled as a real
/// social-platform composer card instead of a bare button. Only a Photo
/// action is offered: a Club can only ever publish a Photo post (see
/// PostsService.createPost) — Video uploads are a Player-only capability
/// on a completely different endpoint, so a "Video" chip here would be a
/// button that always fails. A "Text" chip is omitted for the same reason
/// — the backend has no text-only post type.
class ClubComposerCard extends StatelessWidget {
  const ClubComposerCard({super.key, this.logoUrl, required this.onTap});

  final String? logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.profileColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderOnSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.bg,
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
            child: logoUrl == null
                ? Icon(Icons.shield_outlined, color: colors.textMuted, size: 20)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  l10n.homeFeedComposerPlaceholder,
                  style: TextStyle(color: colors.textMuted, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: l10n.homeFeedNewPostTitle,
            onPressed: onTap,
            icon: Icon(Icons.image_outlined, color: colors.accent),
          ),
        ],
      ),
    );
  }
}
