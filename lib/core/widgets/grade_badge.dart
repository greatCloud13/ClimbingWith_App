import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// V등급(볼더링) 배지. 등급 구간에 따라 색이 바뀌어 한눈에 난이도를 구분한다.
class GradeBadge extends StatelessWidget {
  const GradeBadge({super.key, required this.grade, this.dense = false});

  final String grade; // 예: "V4"
  final bool dense;

  Color get _color {
    final n = int.tryParse(grade.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
    if (n <= 2) return AppColors.gradeEasy;
    if (n <= 5) return AppColors.gradeMid;
    if (n <= 8) return AppColors.gradeHard;
    return AppColors.gradeExtreme;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 11 : 13,
        ),
      ),
    );
  }
}
