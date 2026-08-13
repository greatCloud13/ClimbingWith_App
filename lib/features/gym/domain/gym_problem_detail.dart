import 'package:flutter/material.dart';
import 'gym_problem.dart';

/// GET /api/problem/{id}/detail 응답 — 문제 상세조회 화면 전용.
/// 목록용 [GymProblem]과 달리 홀드 갯수·내 트라이 횟수·내 최고 도달 지점을
/// 포함한다(전부 로그인한 사용자 기준 — 서버가 `getProblemDetail(id, userId)`로
/// 계산).
class GymProblemDetail {
  const GymProblemDetail({
    required this.id,
    required this.settingId,
    required this.title,
    required this.problemType,
    required this.gymLevel,
    required this.holdCount,
    required this.myTryCount,
    required this.clearCount,
    this.levelId,
    this.colorCode,
    this.description,
    this.evaluation,
    this.myBestDropPoint,
    this.isGuestPreview = false,
  });

  final int id;
  final int settingId;
  final String title;
  final String problemType;
  final String gymLevel;
  final int holdCount;

  /// 로그인한 사용자가 이 문제를 시도한 횟수(개인 기준).
  final int myTryCount;
  final int clearCount;
  final int? levelId;
  final String? colorCode;
  final String? description;
  final double? evaluation;

  /// 로그인한 사용자가 이 문제에서 도달한 최고 지점(1-based 홀드 순번).
  /// holdCount와 같으면 완등. 트라이 기록이 없으면 null.
  final int? myBestDropPoint;

  /// true면 `GET /api/problem/{id}/detail`이 비로그인(403)이라 공개 정보
  /// (`GET /api/problem/{id}`)로 대체 구성한 "게스트 체험" 데이터 — holdCount는
  /// 실제 값이 아니라 목업이고, myTryCount/myBestDropPoint는 항상 비어있다.
  final bool isGuestPreview;

  Color? get levelColor => parseHexColor(colorCode);

  bool get isClearedByMe => myBestDropPoint != null && myBestDropPoint! >= holdCount;

  factory GymProblemDetail.fromJson(Map<String, dynamic> json) => GymProblemDetail(
    id: json['id'] as int,
    settingId: json['settingId'] as int,
    title: json['title'] as String,
    problemType: json['problemType'] as String,
    gymLevel: json['gymLevel'] as String? ?? '',
    holdCount: json['holdCount'] as int? ?? 0,
    myTryCount: (json['myTryCount'] as num?)?.toInt() ?? 0,
    clearCount: (json['clearCount'] as num?)?.toInt() ?? 0,
    levelId: json['levelId'] as int?,
    colorCode: json['colorCode'] as String?,
    description: json['description'] as String?,
    evaluation: (json['evaluation'] as num?)?.toDouble(),
    myBestDropPoint: json['myBestDropPoint'] as int?,
  );
}
