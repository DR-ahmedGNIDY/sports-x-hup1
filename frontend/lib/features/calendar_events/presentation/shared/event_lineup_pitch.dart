import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../player/domain/entities/basketball_position.dart';
import '../../../player/domain/entities/football_position.dart';
import '../../../player/presentation/shared/basketball_court_painter.dart';
import '../../../player/presentation/shared/football_pitch_painter.dart';
import '../../domain/entities/calendar_event.dart';

/// The sport-aware lineup diagram on the event detail page: the same pitch
/// or court background the player-profile position section uses, with a
/// new label layer this feature adds — each participant's name at their
/// assigned marker, stacking up to two names when two players share one.
/// (The existing canvases only highlight *one* player's own markers; they
/// never place multiple players' names, which is why this layer is new
/// rather than reused.)
class EventLineupPitch extends StatelessWidget {
  const EventLineupPitch({
    super.key,
    required this.participants,
    required this.participantNames,
    required this.isBasketball,
  });

  final List<CalendarEventParticipant> participants;

  /// playerId -> display name.
  final Map<String, String> participantNames;

  /// `false` renders the football pitch (the default), `true` the
  /// basketball half-court.
  final bool isBasketball;

  static const _footballPainter = FootballPitchPainter();
  static const _basketballPainter = BasketballCourtPainter();

  @override
  Widget build(BuildContext context) {
    final namesByCode = <String, List<String>>{};
    for (final participant in participants) {
      final name = participantNames[participant.playerId] ?? participant.playerId;
      final codes = isBasketball
          ? parseBasketballPositions(participant.position)
          : parseFootballPositions(participant.position);
      final code = codes.isNotEmpty ? codes.first : null;
      if (code == null) continue;
      namesByCode.putIfAbsent(code, () => []).add(name);
    }

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
                Positioned.fill(
                  child: CustomPaint(
                    painter: isBasketball ? _basketballPainter : _footballPainter,
                  ),
                ),
                if (isBasketball)
                  for (final marker in basketballPositionMarkers)
                    _buildLabel(
                      _basketballPainter.toScreen(rect, marker.location.dx, marker.location.dy),
                      namesByCode[marker.code] ?? const [],
                    )
                else
                  for (final marker in footballPositionMarkers)
                    _buildLabel(
                      _footballPainter.toScreen(rect, marker.location.dx, marker.location.dy),
                      namesByCode[marker.code] ?? const [],
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(Offset center, List<String> names) {
    if (names.isEmpty) return const SizedBox.shrink();
    // Up to two names stack vertically at the marker; a third or more
    // participant sharing one marker is summarized rather than overflowing
    // the pitch.
    final shown = names.length > 2 ? [names[0], '+${names.length - 1}'] : names;
    return Positioned(
      left: center.dx - 60,
      top: center.dy - 14,
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final name in shown)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
