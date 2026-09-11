/// One candidate player offered at the roster-confirm step — just enough
/// to render a checkbox row and seed the position-assignment default.
class RosterPoolPlayer {
  const RosterPoolPlayer({
    required this.id,
    this.firstName,
    this.lastName,
    this.position,
    this.dateOfBirth,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? position;
  final DateTime? dateOfBirth;

  String get fullName =>
      [firstName, lastName].where((part) => part != null && part.isNotEmpty).join(' ');
}

class RosterPoolGroup {
  const RosterPoolGroup({required this.birthYear, required this.players});

  final int? birthYear;
  final List<RosterPoolPlayer> players;
}
