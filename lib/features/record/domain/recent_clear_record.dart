import 'package:flutter/material.dart';
import '../../gym/domain/gym_problem.dart' show parseHexColor;

/// GET /api/clearRecord/user/{userId} 응답 항목 — "최근 완등 기록" 화면 전용.
/// 최신 일자순으로 정렬되어 내려온다.
class RecentClearRecord {
  const RecentClearRecord({
    required this.clearRecordId,
    required this.problemId,
    required this.problemName,
    required this.level,
    this.levelColorCode,
    required this.gymId,
    required this.gymName,
    required this.sectorId,
    required this.sectorName,
    required this.settingId,
    required this.clearDate,
    required this.tryCount,
  });

  final int clearRecordId;
  final int problemId;
  final String problemName;
  final String level;
  final String? levelColorCode;
  final int gymId;
  final String gymName;
  final int sectorId;
  final String sectorName;
  final int settingId;
  final String clearDate;
  final int tryCount;

  Color? get levelColor => parseHexColor(levelColorCode);

  factory RecentClearRecord.fromJson(Map<String, dynamic> json) => RecentClearRecord(
    clearRecordId: json['clearRecordId'] as int,
    problemId: json['problemId'] as int,
    problemName: json['problemName'] as String? ?? '',
    level: json['level'] as String? ?? '',
    levelColorCode: json['levelColorCode'] as String?,
    gymId: json['gymId'] as int,
    gymName: json['gymName'] as String? ?? '',
    sectorId: json['sectorId'] as int,
    sectorName: json['sectorName'] as String? ?? '',
    settingId: json['settingId'] as int,
    clearDate: json['clearDate'] as String? ?? '',
    tryCount: (json['tryCount'] as num?)?.toInt() ?? 0,
  );
}

/// GET /api/clearRecord/user/{userId} 페이지 응답.
class RecentClearRecordPage {
  const RecentClearRecordPage({required this.records, required this.isLast});

  final List<RecentClearRecord> records;
  final bool isLast;

  factory RecentClearRecordPage.fromJson(Map<String, dynamic> json) => RecentClearRecordPage(
    records: (json['content'] as List<dynamic>)
        .map((e) => RecentClearRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    isLast: json['last'] as bool? ?? true,
  );
}
