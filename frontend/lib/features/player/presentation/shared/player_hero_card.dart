import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import 'player_profile_data.dart';

/// The redesigned Player Profile's hero block — the single biggest
/// visual element on the page, meant to read like the cover of a
/// professional scouting portfolio rather than a form header. Shows only
/// data that already exists on [PlayerProfile] (photo, name, position,
/// city/country); [actions] is an optional slot the caller fills with
/// edit/share buttons so this widget stays agnostic to who's allowed to
/// do what — the owner-vs-public decision is made by the page, not here.
///
/// [compact] switches between the mobile layout (a smaller portrait
/// photo beside the identity block) and the desktop layout (a large
/// photo, bigger type) — same content, different proportions, matching
/// how the rest of this feature already splits mobile/desktop
/// presentation rather than scaling one layout up or down.
class PlayerHeroCard extends StatelessWidget {
  const PlayerHeroCard({super.key, required this.profile, this.compact = false, this.actions});

  final PlayerProfile profile;
  final bool compact;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photo = profile.profilePhoto;
    final name = profile.fullName.isEmpty ? l10n.unnamedPlayer : profile.fullName;
    final positionLine = playerPositionSummary(profile);
    final location = [
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    final photoBox = ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      child: Container(
        width: compact ? 92 : 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: photo != null
              ? Image.network(photo.secureUrl, fit: BoxFit.cover)
              : ColoredBox(
                  color: AppColors.profileBg,
                  child: Icon(Icons.person, size: compact ? 40 : 88, color: AppColors.greyLight),
                ),
        ),
      ),
    );

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayerProfileBadge(compact: compact, label: l10n.playerProfileBadge),
        SizedBox(height: compact ? 8 : 14),
        Text(
          name,
          style: TextStyle(
            color: AppColors.profileText,
            fontSize: compact ? 20 : 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (positionLine.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 8),
          Text(
            positionLine,
            style: TextStyle(
              color: AppColors.profileAccent,
              fontSize: compact ? 13 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (location.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined, size: compact ? 13 : 16, color: AppColors.greyLight),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.greyLight, fontSize: compact ? 12 : 14),
                ),
              ),
            ],
          ),
        ],
        if (actions != null) ...[SizedBox(height: compact ? 10 : 18), actions!],
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 18 : 22),
      child: Stack(
        children: [
          const Positioned.fill(child: _HeroBackdrop()),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.profileAccent.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 28, offset: const Offset(0, 12)),
              ],
            ),
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Row(
              crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                photoBox,
                SizedBox(width: compact ? 14 : 32),
                Expanded(child: identity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerProfileBadge extends StatelessWidget {
  const _PlayerProfileBadge({required this.compact, required this.label});

  final bool compact;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: AppColors.profileAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.profileAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: compact ? 11 : 13, color: AppColors.profileAccent),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.profileAccent,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// A faint, purely-decorative sports backdrop behind the hero card's
/// content — two soft floodlight glows plus a diagonal stripe pattern,
/// all drawn in code (no image asset, so no licensing/asset-pipeline
/// concerns). Kept low-alpha throughout so it never competes with the
/// player's photo or text on top of it.
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.profileSurface, Color(0xFF0F1520)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -70, right: -50, child: _Glow(color: AppColors.profileAccent.withValues(alpha: 0.14))),
          Positioned(
            bottom: -80,
            left: -60,
            child: _Glow(color: AppColors.profileNeonGreen.withValues(alpha: 0.06)),
          ),
          Positioned.fill(child: CustomPaint(painter: _StripePainter())),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 18;
    const gap = 34.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
