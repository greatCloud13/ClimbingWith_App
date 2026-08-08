import 'package:flutter/material.dart';

/// 암장마다 자체적으로 쓰는 난이도(테이프) 색 체계. 색상 구성과 단계 수가
/// 암장별로 다르다 — 앱 공통 UI 컬러(AppColors.hold*)와는 별개 개념.
class DifficultyLevel {
  const DifficultyLevel({required this.label, required this.color});

  final String label;
  final Color color;
}
