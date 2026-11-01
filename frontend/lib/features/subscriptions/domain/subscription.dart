/// Mirrors `toSubscriptionView` and the club overview on the backend
/// (`backend/src/player-subscriptions/`). Dates stay 'YYYY-MM-DD' strings —
/// calendar days in the academy's zone, never instants — and are only
/// reformatted for display.
library;

enum SubscriptionPlan {
  monthly('MONTHLY'),
  quarterly('QUARTERLY'),
  custom('CUSTOM');

  const SubscriptionPlan(this.wireValue);
  final String wireValue;

  static SubscriptionPlan fromWire(String? value) => values.firstWhere(
    (plan) => plan.wireValue == value,
    orElse: () => custom,
  );
}

enum SubscriptionStatus {
  active('ACTIVE'),
  expiring('EXPIRING'),
  expired('EXPIRED'),
  none('NONE');

  const SubscriptionStatus(this.wireValue);
  final String wireValue;

  static SubscriptionStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wireValue == value,
    orElse: () => none,
  );
}

class PlayerSubscription {
  const PlayerSubscription({
    required this.id,
    required this.playerUserId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.amountMinor,
    required this.paidMinor,
    this.notes,
  });

  final String id;
  final String playerUserId;
  final SubscriptionPlan plan;
  final String startDate;
  final String endDate;
  final int amountMinor;
  final int paidMinor;
  final String? notes;

  bool get fullyPaid => paidMinor >= amountMinor;

  static PlayerSubscription fromJson(Map<String, dynamic> json) =>
      PlayerSubscription(
        id: json['id'] as String,
        playerUserId: json['playerUserId'] as String? ?? '',
        plan: SubscriptionPlan.fromWire(json['plan'] as String?),
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        amountMinor: (json['amountMinor'] as num?)?.toInt() ?? 0,
        paidMinor: (json['paidMinor'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String?,
      );

  static PlayerSubscription? fromJsonOrNull(Object? json) =>
      json is Map<String, dynamic> ? fromJson(json) : null;
}

String _joinName(String? first, String? last) => [first, last]
    .whereType<String>()
    .where((part) => part.trim().isNotEmpty)
    .join(' ');

/// One roster row on the club's subscriptions page.
class RosterSubscription {
  const RosterSubscription({
    required this.playerUserId,
    required this.status,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.current,
  });

  final String playerUserId;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final SubscriptionStatus status;
  final PlayerSubscription? current;

  String get name => _joinName(firstName, lastName);

  static RosterSubscription fromJson(Map<String, dynamic> json) =>
      RosterSubscription(
        playerUserId: json['playerUserId'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        status: SubscriptionStatus.fromWire(json['status'] as String?),
        current: PlayerSubscription.fromJsonOrNull(json['current']),
      );
}

class ClubSubscriptionsOverview {
  const ClubSubscriptionsOverview({
    required this.counts,
    required this.unpaid,
    required this.items,
  });

  final Map<SubscriptionStatus, int> counts;
  final int unpaid;
  final List<RosterSubscription> items;

  static ClubSubscriptionsOverview fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};
    return ClubSubscriptionsOverview(
      counts: {
        for (final status in SubscriptionStatus.values)
          status: (counts[status.wireValue] as num?)?.toInt() ?? 0,
      },
      unpaid: (counts['unpaid'] as num?)?.toInt() ?? 0,
      items: [
        for (final row in json['items'] as List<dynamic>? ?? const [])
          RosterSubscription.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

/// One player's page: who they are, how to reach them, and every period.
class PlayerSubscriptionDetail {
  const PlayerSubscriptionDetail({
    required this.playerUserId,
    required this.status,
    required this.history,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.whatsAppPhone,
  });

  final String playerUserId;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;

  /// International, digits only — ready for wa.me. Null when the player has
  /// no number on file.
  final String? whatsAppPhone;
  final SubscriptionStatus status;
  final List<PlayerSubscription> history;

  PlayerSubscription? get current => history.isEmpty ? null : history.first;

  String get name => _joinName(firstName, lastName);

  static PlayerSubscriptionDetail fromJson(Map<String, dynamic> json) =>
      PlayerSubscriptionDetail(
        playerUserId: json['playerUserId'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        whatsAppPhone: json['whatsAppPhone'] as String?,
        status: SubscriptionStatus.fromWire(json['status'] as String?),
        history: [
          for (final row in json['history'] as List<dynamic>? ?? const [])
            PlayerSubscription.fromJson(row as Map<String, dynamic>),
        ],
      );
}

/// The player's own view.
class MySubscription {
  const MySubscription({required this.status, this.clubName, this.current});

  final SubscriptionStatus status;
  final String? clubName;
  final PlayerSubscription? current;

  static MySubscription fromJson(Map<String, dynamic> json) => MySubscription(
    status: SubscriptionStatus.fromWire(json['status'] as String?),
    clubName: json['clubName'] as String?,
    current: PlayerSubscription.fromJsonOrNull(json['current']),
  );
}

/// '2026-11-30' → '2026/11/30', the way the rest of the app writes dates.
String displayDate(String isoDate) => isoDate.replaceAll('-', '/');

/// A picked day as the API wants it.
String isoDateOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
