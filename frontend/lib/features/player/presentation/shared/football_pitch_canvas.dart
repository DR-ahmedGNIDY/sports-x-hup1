import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/football_position.dart';
import 'football_pitch_painter.dart';

/// The pitch + interactive position markers. Shared by every desktop and
/// mobile presentation so the pitch geometry, marker placement, and
/// selection logic only exist once — the desktop and mobile widgets that
/// wrap this only differ in chrome (headers, side panels, sizing), not in
/// how the pitch itself is drawn or how positions are matched.
///
/// [positions] is the player's parsed position codes, primary first (see
/// [parseFootballPositions]). In view mode this is purely a display; in
/// edit mode tapping a marker reports its code via [onPositionTap] and the
/// caller owns the resulting selection state.
class FootballPitchCanvas extends StatelessWidget {
  const FootballPitchCanvas({
    super.key,
    required this.positions,
    this.markerRadius = 22,
    this.editable = false,
    this.onPositionTap,
    this.onPositionLongPress,
  });

  final List<String> positions;
  final double markerRadius;
  final bool editable;
  final ValueChanged<String>? onPositionTap;
  final ValueChanged<String>? onPositionLongPress;

  static const _painter = FootballPitchPainter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = positions.isNotEmpty ? positions.first : null;
    final secondary = positions.length > 1 ? positions.sublist(1).toSet() : const <String>{};

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final rect = Offset.zero & size;
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _painter)),
                for (final marker in footballPositionMarkers)
                  _buildMarker(context, l10n, marker, rect, primary, secondary),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarker(
    BuildContext context,
    AppLocalizations l10n,
    FootballPositionMarker marker,
    Rect rect,
    String? primary,
    Set<String> secondary,
  ) {
    final center = _painter.toScreen(rect, marker.location.dx, marker.location.dy);
    final isPrimary = marker.code == primary;
    final isSecondary = !isPrimary && secondary.contains(marker.code);
    final fullName = footballPositionFullName(l10n, marker.code);

    return Positioned(
      left: center.dx - markerRadius,
      top: center.dy - markerRadius,
      width: markerRadius * 2,
      height: markerRadius * 2,
      child: Semantics(
        label: fullName,
        selected: isPrimary || isSecondary,
        button: editable,
        child: Tooltip(
          message: fullName,
          child: MouseRegion(
            cursor: editable ? SystemMouseCursors.click : MouseCursor.defer,
            child: GestureDetector(
              onTap: editable ? () => onPositionTap?.call(marker.code) : null,
              onLongPress: editable ? () => onPositionLongPress?.call(marker.code) : null,
              child: _PositionMarker(
                code: marker.code,
                radius: markerRadius,
                isPrimary: isPrimary,
                isSecondary: isSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionMarker extends StatelessWidget {
  const _PositionMarker({
    required this.code,
    required this.radius,
    required this.isPrimary,
    required this.isSecondary,
  });

  final String code;
  final double radius;
  final bool isPrimary;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    List<BoxShadow>? glow;

    if (isPrimary) {
      background = AppColors.pitchPrimary;
      foreground = AppColors.white;
      border = AppColors.white;
      glow = [BoxShadow(color: AppColors.pitchPrimary.withValues(alpha: 0.55), blurRadius: 16, spreadRadius: 1)];
    } else if (isSecondary) {
      background = AppColors.success;
      foreground = AppColors.white;
      border = AppColors.white;
      glow = [BoxShadow(color: AppColors.success.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 0.5)];
    } else {
      background = AppColors.offWhite;
      foreground = AppColors.black;
      border = Colors.white.withValues(alpha: 0.5);
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: border, width: isPrimary ? 2.2 : 1.4),
        boxShadow: glow,
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(
            code,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.42,
              letterSpacing: 0.2,
            ),
          ),
          if (isPrimary)
            Positioned(
              top: -radius * 0.28,
              right: -radius * 0.28,
              child: Container(
                width: radius * 0.62,
                height: radius * 0.62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pitchPrimary,
                  border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.4)),
                ),
                child: Icon(Icons.check, size: radius * 0.4, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}
