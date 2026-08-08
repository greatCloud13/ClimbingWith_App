import 'package:flutter/material.dart';
import 'difficulty_level.dart';
import 'gym_type.dart';
import 'price_plan.dart';
import 'sector.dart';

class GymDetail {
  const GymDetail({
    required this.id,
    required this.name,
    required this.accent,
    required this.gymType,
    required this.businessHours,
    required this.address,
    required this.hashtags,
    required this.photos,
    required this.pricePlans,
    this.boulderDifficultySystem = const [],
    this.leadDifficultySystem = const [],
    required this.sectors,
  });

  final String id;
  final String name;
  final Color accent;
  final GymType gymType;
  final String businessHours;
  final String address;
  final List<String> hashtags;

  /// 갤러리 사진 — 실제 이미지 자산이 없어 색상만 다른 플레이스홀더로 목업.
  final List<Color> photos;
  final List<PricePlan> pricePlans;

  /// 볼더링 난이도 체계(왼쪽=쉬움 → 오른쪽=어려움 색 스트립). gymType이 lead면 비어있음.
  final List<DifficultyLevel> boulderDifficultySystem;

  /// 리드 난이도 체계(라벨+색 리스트). gymType이 boulder면 비어있음.
  final List<DifficultyLevel> leadDifficultySystem;

  final List<Sector> sectors;
}
