import 'package:flutter/material.dart';
import 'notice.dart';

class FavoriteGym {
  const FavoriteGym({
    required this.name,
    required this.area,
    required this.accent,
    required this.notice,
  });

  final String name;
  final String area;
  final Color accent;

  /// 이 암장의 공지. 전역 공지 슬라이드가 아니라 암장 카드에 종속된 공지.
  final Notice notice;
}
