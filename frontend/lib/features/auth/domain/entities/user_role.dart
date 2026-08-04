enum UserRole {
  player('PLAYER'),
  club('CLUB'),
  admin('ADMIN');

  const UserRole(this.wireValue);

  final String wireValue;

  static UserRole fromWire(String value) => switch (value) {
    'PLAYER' => UserRole.player,
    'CLUB' => UserRole.club,
    'ADMIN' => UserRole.admin,
    _ => throw ArgumentError('Unknown role: $value'),
  };
}
