enum UserRole {
  player('PLAYER'),
  club('CLUB'),
  coach('COACH'),
  admin('ADMIN');

  const UserRole(this.wireValue);

  final String wireValue;

  static UserRole fromWire(String value) => switch (value) {
    'PLAYER' => UserRole.player,
    'CLUB' => UserRole.club,
    'COACH' => UserRole.coach,
    'ADMIN' => UserRole.admin,
    _ => throw ArgumentError('Unknown role: $value'),
  };
}
