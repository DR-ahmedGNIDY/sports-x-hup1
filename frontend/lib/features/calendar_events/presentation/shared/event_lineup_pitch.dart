import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../player/domain/entities/basketball_position.dart';
import '../../../player/domain/entities/football_position.dart';
import '../../../player/presentation/shared/basketball_court_painter.dart';
import '../../../player/presentation/shared/football_pitch_painter.dart';
import '../../domain/entities/calendar_event.dart';

/// One player as the lineup needs them: who to name on the pitch, and what
/// to show when their spot is tapped.
class LineupPlayer {
  const LineupPlayer({required this.id, required this.name, this.photoUrl});

  final String id;
  final String name;
  final String? photoUrl;
}

/// The sport-aware lineup diagram on the event detail page: the same pitch
/// or court the player-profile position section draws, with the same marker
/// circles, and each assigned player's name above their marker — stacked
/// when two players share one.
class EventLineupPitch extends StatelessWidget {
  const EventLineupPitch({
    super.key,
    required this.participants,
    required this.players,
    required this.isBasketball,
    this.markerRadius = 20,
  });

  final List<CalendarEventParticipant> participants;

  /// playerId -> the player behind it.
  final Map<String, LineupPlayer> players;

  /// `false` renders the football pitch (the default), `true` the
  /// basketball half-court.
  final bool isBasketball;

  final double markerRadius;

  static const _footballPainter = FootballPitchPainter();
  static const _basketballPainter = BasketballCourtPainter();

  @override
  Widget build(BuildContext context) {
    final markers = _collapseByCode(
      isBasketball
          ? [
              for (final m in basketballPositionMarkers)
                (id: m.id, code: m.code, location: m.location),
            ]
          : [
              for (final m in footballPositionMarkers)
                (id: m.id, code: m.code, location: m.location),
            ],
    );

    final byMarkerId = _assignToMarkers(markers);

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
            final rect = Offset.zero & constraints.biggest;
            final painter = isBasketball ? _basketballPainter : _footballPainter;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: painter)),
                for (final marker in markers)
                  _buildMarker(
                    context,
                    center: isBasketball
                        ? _basketballPainter.toScreen(
                            rect,
                            marker.location.dx,
                            marker.location.dy,
                          )
                        : _footballPainter.toScreen(
                            rect,
                            marker.location.dx,
                            marker.location.dy,
                          ),
                    code: marker.code,
                    assigned: byMarkerId[marker.id] ?? const [],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// One circle per position: the profile pitch draws two centre-back spots,
  /// but a lineup names the players at a position rather than the slots, so
  /// the duplicates merge into a single marker halfway between them.
  List<({String id, String code, Offset location})> _collapseByCode(
    List<({String id, String code, Offset location})> markers,
  ) {
    final byCode = <String, List<({String id, String code, Offset location})>>{};
    for (final marker in markers) {
      byCode.putIfAbsent(marker.code, () => []).add(marker);
    }
    return [
      for (final entry in byCode.entries)
        (
          id: entry.key,
          code: entry.key,
          location: Offset(
            entry.value.map((m) => m.location.dx).reduce((a, b) => a + b) /
                entry.value.length,
            entry.value.map((m) => m.location.dy).reduce((a, b) => a + b) /
                entry.value.length,
          ),
        ),
    ];
  }

  /// Every player at a position stacks on that position's single marker.
  Map<String, List<LineupPlayer>> _assignToMarkers(
    List<({String id, String code, Offset location})> markers,
  ) {
    final markerIdsByCode = <String, List<String>>{};
    for (final marker in markers) {
      markerIdsByCode.putIfAbsent(marker.code, () => []).add(marker.id);
    }

    final result = <String, List<LineupPlayer>>{};
    final playersByCode = <String, List<LineupPlayer>>{};
    for (final participant in participants) {
      final player = players[participant.playerId];
      if (player == null) continue;
      final codes = isBasketball
          ? parseBasketballPositions(participant.position)
          : parseFootballPositions(participant.position);
      if (codes.isEmpty) continue;
      playersByCode.putIfAbsent(codes.first, () => []).add(player);
    }

    for (final entry in playersByCode.entries) {
      final markerIds = markerIdsByCode[entry.key];
      if (markerIds == null || markerIds.isEmpty) continue;
      for (var i = 0; i < entry.value.length; i++) {
        final markerId = markerIds[i % markerIds.length];
        result.putIfAbsent(markerId, () => []).add(entry.value[i]);
      }
    }
    return result;
  }

  Widget _buildMarker(
    BuildContext context, {
    required Offset center,
    required String code,
    required List<LineupPlayer> assigned,
  }) {
    const labelWidth = 120.0;
    final isTaken = assigned.isNotEmpty;

    return Positioned(
      left: center.dx - labelWidth / 2,
      // Room above the circle for one or two stacked names.
      top: center.dy - markerRadius - 34,
      width: labelWidth,
      child: GestureDetector(
        onTap: isTaken ? () => _showPlayers(context, code, assigned) : null,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final player in assigned.take(2))
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  player.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (assigned.length > 2)
              Text(
                '+${assigned.length - 2}',
                style: const TextStyle(color: AppColors.white, fontSize: 10),
              ),
            _PositionCircle(code: code, radius: markerRadius, isTaken: isTaken),
          ],
        ),
      ),
    );
  }

  void _showPlayers(
    BuildContext context,
    String code,
    List<LineupPlayer> assigned,
  ) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(code),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final player in assigned)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: player.photoUrl != null
                      ? NetworkImage(player.photoUrl!)
                      : null,
                  child: player.photoUrl == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                title: Text(player.name),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _PositionCircle extends StatelessWidget {
  const _PositionCircle({
    required this.code,
    required this.radius,
    required this.isTaken,
  });

  final String code;
  final double radius;
  final bool isTaken;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTaken ? AppColors.pitchPrimary : AppColors.offWhite,
        border: Border.all(
          color: isTaken ? AppColors.white : Colors.white.withValues(alpha: 0.5),
          width: isTaken ? 2.2 : 1.4,
        ),
        boxShadow: isTaken
            ? [
                BoxShadow(
                  color: AppColors.pitchPrimary.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: TextStyle(
          color: isTaken ? AppColors.white : AppColors.black,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.42,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
