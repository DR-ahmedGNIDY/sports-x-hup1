enum PreferredFoot {
  left('LEFT', 'Left'),
  right('RIGHT', 'Right'),
  both('BOTH', 'Both');

  const PreferredFoot(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static PreferredFoot? fromWire(String? value) {
    if (value == null) return null;
    return PreferredFoot.values.firstWhere((v) => v.wireValue == value);
  }
}

enum ProfileVisibility {
  public('PUBLIC', 'Public'),
  private('PRIVATE', 'Private');

  const ProfileVisibility(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ProfileVisibility fromWire(String value) {
    return ProfileVisibility.values.firstWhere((v) => v.wireValue == value);
  }
}

enum PlayerMediaType {
  photo('PHOTO'),
  video('VIDEO');

  const PlayerMediaType(this.wireValue);

  final String wireValue;

  static PlayerMediaType fromWire(String value) {
    return PlayerMediaType.values.firstWhere((v) => v.wireValue == value);
  }
}
