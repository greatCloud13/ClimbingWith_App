import 'package:flutter/material.dart';
import 'notice.dart';

class FavoriteGym {
  const FavoriteGym({
    required this.id,
    required this.name,
    required this.area,
    required this.accent,
    required this.notice,
  });

  /// 암장 목록/상세 화면과 동일한 id — 상세 화면(/gym/:id)으로 바로 연결하는 데 쓴다.
  final String id;
  final String name;
  final String area;
  final Color accent;

  /// 이 암장의 공지. 전역 공지 슬라이드가 아니라 암장 카드에 종속된 공지.
  final Notice notice;
}
