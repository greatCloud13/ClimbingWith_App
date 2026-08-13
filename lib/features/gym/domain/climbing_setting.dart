/// 세팅 — 섹터의 '설정'이 아니라, 한 섹터에서 여러 루트(문제)가 유지되는 기간.
/// GET /api/sector/{id} 응답의 settingList 항목.
class ClimbingSetting {
  const ClimbingSetting({
    required this.id,
    required this.sector,
    required this.gym,
    required this.settingDate,
    required this.startDate,
    this.endDate,
    required this.active,
  });

  final int id;
  final String sector;
  final String gym;
  final String settingDate;
  final String startDate;
  final String? endDate;
  final bool active;

  factory ClimbingSetting.fromJson(Map<String, dynamic> json) =>
      ClimbingSetting(
        id: json['id'] as int,
        sector: json['sector'] as String? ?? '',
        gym: json['gym'] as String? ?? '',
        settingDate: json['settingDate'] as String? ?? '',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String?,
        active: json['active'] as bool? ?? false,
      );
}
