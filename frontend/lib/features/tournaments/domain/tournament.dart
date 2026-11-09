/// Mirrors `tournaments.mapper.ts` on the backend. Ids are strings, dates
/// 'YYYY-MM-DD', times 'HH:mm'.
library;

enum ParticipantType {
  individual('individual'),
  team('team');

  const ParticipantType(this.wireValue);
  final String wireValue;

  static ParticipantType fromWire(String? v) => v == 'team' ? team : individual;
}

enum TournamentFormat {
  league('league'),
  knockout('knockout'),
  groupsKnockout('groups_knockout');

  const TournamentFormat(this.wireValue);
  final String wireValue;

  static TournamentFormat fromWire(String? v) =>
      values.firstWhere((f) => f.wireValue == v, orElse: () => league);
}

enum TournamentStatus {
  draft('draft'),
  running('running'),
  finished('finished');

  const TournamentStatus(this.wireValue);
  final String wireValue;

  static TournamentStatus fromWire(String? v) =>
      values.firstWhere((s) => s.wireValue == v, orElse: () => draft);
}

int _int(Object? v, int fallback) => (v as num?)?.toInt() ?? fallback;

class ScoringSettings {
  const ScoringSettings({
    this.mode = 'goals',
    this.bestOf = 3,
    this.pointsPerSet = 11,
    this.winByTwo = true,
    this.maxPointsPerSet,
  });

  /// 'goals' or 'sets'.
  final String mode;
  final int bestOf;
  final int pointsPerSet;
  final bool winByTwo;
  final int? maxPointsPerSet;

  bool get bySets => mode == 'sets';

  static ScoringSettings fromJson(Map<String, dynamic>? j) => ScoringSettings(
    mode: j?['mode'] as String? ?? 'goals',
    bestOf: _int(j?['bestOf'], 3),
    pointsPerSet: _int(j?['pointsPerSet'], 11),
    winByTwo: j?['winByTwo'] as bool? ?? true,
    maxPointsPerSet: (j?['maxPointsPerSet'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'bestOf': bestOf,
    'pointsPerSet': pointsPerSet,
    'winByTwo': winByTwo,
    'maxPointsPerSet': maxPointsPerSet,
  };
}

class LeagueSettings {
  const LeagueSettings({
    this.winPoints = 3,
    this.drawPoints = 1,
    this.lossPoints = 0,
    this.doubleRound = false,
    this.allowDraws = true,
  });

  final int winPoints;
  final int drawPoints;
  final int lossPoints;
  final bool doubleRound;
  final bool allowDraws;

  static LeagueSettings fromJson(Map<String, dynamic>? j) => LeagueSettings(
    winPoints: _int(j?['winPoints'], 3),
    drawPoints: _int(j?['drawPoints'], 1),
    lossPoints: _int(j?['lossPoints'], 0),
    doubleRound: j?['doubleRound'] as bool? ?? false,
    allowDraws: j?['allowDraws'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'winPoints': winPoints,
    'drawPoints': drawPoints,
    'lossPoints': lossPoints,
    'doubleRound': doubleRound,
    'allowDraws': allowDraws,
  };
}

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.participantType,
    required this.format,
    required this.status,
    this.drawMode = 'random',
    this.sportId,
    this.ageGroup = '',
    this.startDate,
    this.endDate,
    this.notes = '',
    this.scoring = const ScoringSettings(),
    this.league = const LeagueSettings(),
    this.groupsCount = 2,
    this.qualifiersPerGroup = 2,
    this.penaltiesEnabled = true,
    this.penaltiesCount = 5,
    this.visibleToPlayers = true,
    this.participantsCount = 0,
    this.isParticipant = false,
  });

  final String id;
  final String name;
  final String? sportId;
  final String ageGroup;
  final String? startDate;
  final String? endDate;
  final String notes;
  final ParticipantType participantType;
  final TournamentFormat format;

  /// 'random' or 'directed'.
  final String drawMode;
  final ScoringSettings scoring;
  final LeagueSettings league;
  final int groupsCount;
  final int qualifiersPerGroup;
  final bool penaltiesEnabled;
  final int penaltiesCount;
  final TournamentStatus status;
  final bool visibleToPlayers;

  /// List rows only.
  final int participantsCount;

  /// The player portal's list only.
  final bool isParticipant;

  bool get isDraft => status == TournamentStatus.draft;
  bool get hasStandings => format != TournamentFormat.knockout;
  bool get hasBracket => format != TournamentFormat.league;

  static Tournament fromJson(Map<String, dynamic> j) {
    final groups = j['groups'] as Map<String, dynamic>?;
    final knockout = j['knockout'] as Map<String, dynamic>?;
    return Tournament(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      sportId: j['sportId'] as String?,
      ageGroup: j['ageGroup'] as String? ?? '',
      startDate: j['startDate'] as String?,
      endDate: j['endDate'] as String?,
      notes: j['notes'] as String? ?? '',
      participantType: ParticipantType.fromWire(
        j['participantType'] as String?,
      ),
      format: TournamentFormat.fromWire(j['format'] as String?),
      drawMode: j['drawMode'] as String? ?? 'random',
      scoring: ScoringSettings.fromJson(j['scoring'] as Map<String, dynamic>?),
      league: LeagueSettings.fromJson(j['league'] as Map<String, dynamic>?),
      groupsCount: _int(groups?['count'], 2),
      qualifiersPerGroup: _int(groups?['qualifiersPerGroup'], 2),
      penaltiesEnabled: knockout?['penaltiesEnabled'] as bool? ?? true,
      penaltiesCount: _int(knockout?['penaltiesCount'], 5),
      status: TournamentStatus.fromWire(j['status'] as String?),
      visibleToPlayers: j['visibleToPlayers'] as bool? ?? true,
      participantsCount: _int(j['participantsCount'], 0),
      isParticipant: j['isParticipant'] as bool? ?? false,
    );
  }
}

class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.playerUserIds,
    this.captainUserId,
    this.seed,
    this.groupIndex,
  });

  final String id;
  final String name;
  final List<String> playerUserIds;
  final String? captainUserId;
  final int? seed;
  final int? groupIndex;

  static Participant fromJson(Map<String, dynamic> j) => Participant(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    playerUserIds: [
      for (final id in j['playerUserIds'] as List<dynamic>? ?? const [])
        id as String,
    ],
    captainUserId: j['captainUserId'] as String?,
    seed: (j['seed'] as num?)?.toInt(),
    groupIndex: (j['groupIndex'] as num?)?.toInt(),
  );
}

class TournamentPlayer {
  const TournamentPlayer({
    required this.userId,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  final String userId;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;

  String get name => [
    firstName,
    lastName,
  ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');

  static TournamentPlayer fromJson(Map<String, dynamic> j) => TournamentPlayer(
    userId: j['userId'] as String,
    firstName: j['firstName'] as String?,
    lastName: j['lastName'] as String?,
    photoUrl: j['photoUrl'] as String?,
  );
}

class SetScore {
  const SetScore(this.a, this.b);
  final int a;
  final int b;

  Map<String, dynamic> toJson() => {'a': a, 'b': b};
}

class Fixture {
  const Fixture({
    required this.id,
    required this.stage,
    required this.round,
    required this.matchNo,
    required this.status,
    this.groupIndex,
    this.aId,
    this.bId,
    this.scoreA,
    this.scoreB,
    this.sets = const [],
    this.penaltiesA,
    this.penaltiesB,
    this.winnerId,
    this.date,
    this.time,
    this.location = '',
    this.nextMatchNo,
  });

  final String id;

  /// 'league', 'group' or 'knockout'.
  final String stage;
  final int? groupIndex;
  final int round;
  final int matchNo;
  final String? aId;
  final String? bId;
  final int? scoreA;
  final int? scoreB;
  final List<SetScore> sets;
  final int? penaltiesA;
  final int? penaltiesB;
  final String? winnerId;

  /// 'pending', 'played' or 'bye'.
  final String status;
  final String? date;
  final String? time;
  final String location;

  /// Knockout: the match in the next round this one's winner goes to.
  final int? nextMatchNo;

  bool get isPlayed => status == 'played';
  bool get isBye => status == 'bye';
  bool get isKnockout => stage == 'knockout';
  bool involves(String? participantId) =>
      participantId != null && (aId == participantId || bId == participantId);

  static Fixture fromJson(Map<String, dynamic> j) => Fixture(
    id: j['id'] as String,
    stage: j['stage'] as String? ?? 'league',
    groupIndex: (j['groupIndex'] as num?)?.toInt(),
    round: _int(j['round'], 1),
    matchNo: _int(j['matchNo'], 1),
    aId: j['aId'] as String?,
    bId: j['bId'] as String?,
    scoreA: (j['scoreA'] as num?)?.toInt(),
    scoreB: (j['scoreB'] as num?)?.toInt(),
    sets: [
      for (final s in j['sets'] as List<dynamic>? ?? const [])
        SetScore(_int((s as Map<String, dynamic>)['a'], 0), _int(s['b'], 0)),
    ],
    penaltiesA: (j['penaltiesA'] as num?)?.toInt(),
    penaltiesB: (j['penaltiesB'] as num?)?.toInt(),
    winnerId: j['winnerId'] as String?,
    status: j['status'] as String? ?? 'pending',
    date: j['date'] as String?,
    time: j['time'] as String?,
    location: j['location'] as String? ?? '',
    nextMatchNo: (j['nextMatchNo'] as num?)?.toInt(),
  );
}

class StandingRow {
  const StandingRow({
    required this.id,
    required this.position,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.diff,
    required this.points,
    this.scored = 0,
    this.conceded = 0,
  });

  final String id;
  final int position;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int diff;
  final int points;

  /// Goals (or sets) for and against.
  final int scored;
  final int conceded;

  static StandingRow fromJson(Map<String, dynamic> j) => StandingRow(
    id: j['id'] as String,
    position: _int(j['position'], 0),
    played: _int(j['played'], 0),
    won: _int(j['won'], 0),
    drawn: _int(j['drawn'], 0),
    lost: _int(j['lost'], 0),
    diff: _int(j['diff'], 0),
    points: _int(j['points'], 0),
    scored: _int(j['for'], 0),
    conceded: _int(j['against'], 0),
  );
}

class StandingsGroup {
  const StandingsGroup({required this.rows, this.groupIndex});
  final int? groupIndex;
  final List<StandingRow> rows;
}

class TournamentDetail {
  const TournamentDetail({
    required this.tournament,
    required this.participants,
    required this.players,
    required this.fixtures,
    required this.standings,
    this.myParticipantId,
  });

  final Tournament tournament;
  final List<Participant> participants;
  final Map<String, TournamentPlayer> players;
  final List<Fixture> fixtures;
  final List<StandingsGroup> standings;

  /// The player portal only: the participant the viewer plays in.
  final String? myParticipantId;

  Participant? participant(String? id) {
    if (id == null) return null;
    for (final p in participants) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Every player already entered — a player sits in one participant only.
  Set<String> get enteredPlayerIds => {
    for (final p in participants) ...p.playerUserIds,
  };

  bool get anyPlayed => fixtures.any((f) => f.isPlayed);

  static TournamentDetail fromJson(Map<String, dynamic> j) => TournamentDetail(
    tournament: Tournament.fromJson(j['tournament'] as Map<String, dynamic>),
    participants: [
      for (final p in j['participants'] as List<dynamic>? ?? const [])
        Participant.fromJson(p as Map<String, dynamic>),
    ],
    players: {
      for (final p in j['players'] as List<dynamic>? ?? const [])
        (p as Map<String, dynamic>)['userId'] as String:
            TournamentPlayer.fromJson(p),
    },
    fixtures: [
      for (final f in j['fixtures'] as List<dynamic>? ?? const [])
        Fixture.fromJson(f as Map<String, dynamic>),
    ],
    standings: [
      for (final g in j['standings'] as List<dynamic>? ?? const [])
        StandingsGroup(
          groupIndex: ((g as Map<String, dynamic>)['groupIndex'] as num?)
              ?.toInt(),
          rows: [
            for (final r in g['rows'] as List<dynamic>? ?? const [])
              StandingRow.fromJson(r as Map<String, dynamic>),
          ],
        ),
    ],
    myParticipantId: j['myParticipantId'] as String?,
  );
}

/// 'A', 'B', … for a group index.
String groupLetter(int index) => String.fromCharCode(65 + index);
