/// 난이도(레벨) — 암장에 속한 문제 등급 정의. GET/POST/PUT /api/level(/{id}),
/// GET /api/level/gym/{gymId} 응답.
class GymLevel {
  const GymLevel({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.levelName,
    required this.displayOrder,
    this.colorCode,
    this.description,
    this.climbType,
  });

  final int id;
  final int gymId;
  final String gymName;
  final String levelName;
  final int displayOrder;
  final String? colorCode;
  final String? description;

  /// 볼더/리드 종목 구분. 미지정(null)인 기존 데이터가 있어 nullable —
  /// null은 "종목 상관없이 적용"으로 취급한다.
  final String? climbType;

  factory GymLevel.fromJson(Map<String, dynamic> json) => GymLevel(
    id: json['id'] as int,
    gymId: json['gymId'] as int,
    gymName: json['gymName'] as String? ?? '',
    levelName: json['levelName'] as String,
    displayOrder: json['displayOrder'] as int? ?? 0,
    colorCode: json['colorCode'] as String?,
    description: json['description'] as String?,
    climbType: json['climbType'] as String?,
  );
}
