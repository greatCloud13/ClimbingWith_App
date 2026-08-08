import 'package:flutter/material.dart';

/// 클라이밍장 조명 + 홀드 컬러에서 뽑은 다크 무드 팔레트.
/// 임의 생성 금지 — 새 색은 여기 토큰에 추가하고 참조만 할 것.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0B0B0D);
  static const surface = Color(0xFF17171B);
  static const surfaceElevated = Color(0xFF1F1F24);
  static const border = Color(0xFF2A2A30);

  static const textPrimary = Color(0xFFF5F5F2);
  static const textSecondary = Color(0xFF9A9AA3);
  static const textTertiary = Color(0xFF6B6B74);

  // 홀드 액센트 — 남발 금지, 강조 포인트에만 사용
  static const holdLime = Color(0xFFD4FF3D);
  static const holdMagenta = Color(0xFFFF3B7F);
  static const holdCyan = Color(0xFF3DD6FF);

  static const error = Color(0xFFFF5C5C);
  static const success = Color(0xFF4CD97B);

  // 난이도 등급별 색 (V등급 기준, 낮음→높음)
  static const gradeEasy = Color(0xFF4CD97B);
  static const gradeMid = Color(0xFFD4FF3D);
  static const gradeHard = Color(0xFFFF3B7F);
  static const gradeExtreme = Color(0xFFFF5C5C);
}
