import 'package:flutter/material.dart';

class ClimbingProblem {
  const ClimbingProblem({
    required this.id,
    required this.grade,
    required this.tapeColor,
    required this.setter,
    required this.setDate,
  });

  final String id;
  final String grade; // 예: V4
  final Color tapeColor; // 이 문제가 속한 난이도(테이프) 색
  final String setter;
  final String setDate;
}
