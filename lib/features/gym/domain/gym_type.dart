/// 백엔드 GymType enum(BOULDER, LEAD, BOTH)에 대응.
enum GymType {
  boulder,
  lead,
  both;

  static GymType fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'LEAD':
        return GymType.lead;
      case 'BOTH':
        return GymType.both;
      case 'BOULDER':
      default:
        return GymType.boulder;
    }
  }
}
