enum UserRole {
  player('PLAYER'),
  club('CLUB');

  const UserRole(this.wireValue);

  final String wireValue;

  static UserRole fromWire(String value) => switch (value) {
    'PLAYER' => UserRole.player,
    'CLUB' => UserRole.club,
    _ => throw ArgumentError('Unknown role: $value'),
  };
}
