import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'climbing_discipline.dart';
import 'difficulty_level.dart';
import 'gym_type.dart';
import 'price_plan.dart';
import 'sector.dart';

const _accentPalette = [
  AppColors.holdLime,
  AppColors.holdMagenta,
  AppColors.holdCyan,
];

class GymDetail {
  const GymDetail({
    required this.id,
    required this.name,
    required this.accent,
    required this.gymType,
    required this.businessHours,
    required this.address,
    this.hashtags = const [],
    this.photos = const [],
    this.imageUrls = const [],
    this.pricePlans = const [],
    this.boulderDifficultySystem = const [],
    this.leadDifficultySystem = const [],
    this.sectors = const [],
  });

  final String id;
  final String name;
  final Color accent;
  final GymType gymType;
  final String businessHours;
  final String address;
  final List<String> hashtags;

  /// 갤러리 사진 플레이스홀더 색 — 실제 사진(imageUrls)이 없을 때 아이콘 배경으로만 쓰인다.
  final List<Color> photos;

  /// 실제 암장 소개 사진 URL. 비어있으면 photos 색상으로 대체 표시.
  final List<String> imageUrls;
  final List<PricePlan> pricePlans;

  /// 볼더링 난이도 체계(왼쪽=쉬움 → 오른쪽=어려움 색 스트립). 데이터 없으면 비어있음.
  final List<DifficultyLevel> boulderDifficultySystem;

  /// 리드 난이도 체계(라벨+색 리스트). 데이터 없으면 비어있음.
  final List<DifficultyLevel> leadDifficultySystem;

  final List<Sector> sectors;

  /// GET /api/gym/{id} 응답 매핑.
  /// 이 API는 이용권/난이도 체계/섹터별 담당 종목(boulder/lead)을 제공하지 않아
  /// 해당 값은 비어있거나(가격·난이도) gymType 기준으로 단순 추정한다(섹터 종목,
  /// BOTH 암장은 boulder로 가정) — 자세한 내용은 reports/ 참고.
  factory GymDetail.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final gymType = GymType.fromApiValue(
      json['gymType'] as String? ?? 'BOULDER',
    );
    final sectorDiscipline = switch (gymType) {
      GymType.lead => ClimbingDiscipline.lead,
      GymType.boulder || GymType.both => ClimbingDiscipline.boulder,
    };

    final openAt = json['openAt'] as String?;
    final closeAt = json['closeAt'] as String?;
    final weekendOpenAt = json['weekendOpenAt'] as String?;
    final weekendCloseAt = json['weekendCloseAt'] as String?;
    final String businessHours;
    if (openAt != null &&
        closeAt != null &&
        weekendOpenAt != null &&
        weekendCloseAt != null) {
      businessHours = '평일 $openAt–$closeAt · 주말 $weekendOpenAt–$weekendCloseAt';
    } else if (openAt != null && closeAt != null) {
      businessHours = '$openAt–$closeAt';
    } else {
      businessHours = '영업시간 정보 없음';
    }

    final sectorList = json['sectorList'] as List<dynamic>? ?? [];

    return GymDetail(
      id: id.toString(),
      name: json['gymName'] as String,
      accent: _accentPalette[id % _accentPalette.length],
      gymType: gymType,
      businessHours: businessHours,
      address: json['address'] as String? ?? '',
      hashtags: (json['hashtags'] as List<dynamic>? ?? []).cast<String>(),
      imageUrls: (json['introImages'] as List<dynamic>? ?? []).cast<String>(),
      photos: [_accentPalette[id % _accentPalette.length]],
      sectors: sectorList
          .map(
            (e) => Sector.fromApiJson(
              e as Map<String, dynamic>,
              discipline: sectorDiscipline,
            ),
          )
          .toList(),
    );
  }
}
