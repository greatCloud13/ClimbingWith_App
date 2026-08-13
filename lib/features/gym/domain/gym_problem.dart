import 'package:flutter/material.dart';

/// 문제/난이도(레벨) 종목 값. gymLevel의 climbType과 같은 값 집합을 쓴다.
const List<String> climbTypes = ['BOULDER', 'LEAD'];

String climbTypeLabel(String type) => switch (type.toUpperCase()) {
  'BOULDER' => '볼더',
  'LEAD' => '리드',
  _ => type,
};

/// `#RRGGBB`(또는 `#AARRGGBB`) 형태의 색상 코드를 [Color]로 변환한다.
/// 형식이 아니거나 비어있으면 null.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var value = hex.startsWith('#') ? hex.substring(1) : hex;
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// 문제(루트) — 세팅 기간 동안 유지되는 개별 루트.
/// GET/PUT/POST /api/problem(/{id}), GET /api/problem/setting/{id} 등의 응답.
/// 기존 [ClimbingProblem](climbing_problem.dart)은 목업 공개 화면용(V등급·테이프색 중심)
/// 이라 필드가 달라 별도 모델로 둔다.
class GymProblem {
  const GymProblem({
    required this.id,
    required this.settingId,
    required this.title,
    required this.problemType,
    required this.gymLevel,
    required this.clearUserCount,
    this.description,
    this.evaluation,
    this.levelId,
    this.colorCode,
  });

  final int id;
  final int settingId;
  final String title;
  final String problemType;
  final String gymLevel;
  final int clearUserCount;
  final String? description;
  final double? evaluation;

  /// 난이도(GymLevel) id — 없을 수도 있는 필드라 nullable(응답에 따라 미포함).
  final int? levelId;

  /// 난이도 색상 코드(`#RRGGBB`). 없으면 색 표시 없이 텍스트만 보여준다.
  final String? colorCode;

  Color? get levelColor => parseHexColor(colorCode);

  factory GymProblem.fromJson(Map<String, dynamic> json) => GymProblem(
    id: json['id'] as int,
    settingId: json['settingId'] as int,
    title: json['title'] as String,
    problemType: json['problemType'] as String,
    gymLevel: json['gymLevel'] as String? ?? '',
    clearUserCount: json['clearUserCount'] as int? ?? 0,
    description: json['description'] as String?,
    evaluation: (json['evaluation'] as num?)?.toDouble(),
    levelId: json['levelId'] as int?,
    colorCode: json['colorCode'] as String?,
  );
}
