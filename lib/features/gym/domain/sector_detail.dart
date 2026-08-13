import 'climbing_setting.dart';

/// GET /api/sector/{id} 응답 — 섹터 상세 + 세팅 기록 목록.
class SectorDetail {
  const SectorDetail({
    required this.id,
    required this.gymName,
    required this.sectorName,
    this.description,
    this.settingDate,
    this.nextSettingDate,
    required this.problemCount,
    required this.settingList,
  });

  final int id;
  final String gymName;
  final String sectorName;
  final String? description;
  final String? settingDate;
  final String? nextSettingDate;
  final int problemCount;
  final List<ClimbingSetting> settingList;

  factory SectorDetail.fromApiJson(Map<String, dynamic> json) => SectorDetail(
    id: json['id'] as int,
    gymName: json['gymName'] as String? ?? '',
    sectorName: json['sectorName'] as String,
    description: json['description'] as String?,
    settingDate: json['settingDate'] as String?,
    nextSettingDate: json['nextSettingDate'] as String?,
    problemCount: json['problemCount'] as int? ?? 0,
    settingList: (json['settingList'] as List<dynamic>? ?? [])
        .map((e) => ClimbingSetting.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
