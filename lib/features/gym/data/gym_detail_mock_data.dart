import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/climbing_discipline.dart';
import '../domain/climbing_problem.dart';
import '../domain/difficulty_level.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_type.dart';
import '../domain/price_plan.dart';
import '../domain/sector.dart';

/// 암장 상세/섹터/문제 API가 아직 없어 임시로 목업한다.
/// 암장마다 GymType(BOULDER/LEAD/BOTH)과 그에 따른 난이도 체계가 다르다:
/// - 볼더링은 색 스트립(왼쪽=쉬움 → 오른쪽=어려움), 리드는 라벨+색 리스트로 표시.
/// - BOTH인 암장은 두 체계를 모두 갖고 화면에서 좌우 스와이프로 전환한다.
///
/// (const 표현식 안에서는 다른 const 객체의 필드를 다시 참조할 수 없어서,
/// 테이프 색은 원시 Color 상수로 따로 두고 DifficultyLevel과 ClimbingProblem
/// 양쪽에서 같은 상수를 참조한다.)

const _seongsuGreenColor = Color(0xFF4CAF50);
const _seongsuBlueColor = Color(0xFF2E90FA);
const _seongsuRedColor = Color(0xFFE53935);
const _seongsuBlackColor = Color(0xFF3A3A3F);

const _hongdaeBoulderYellowColor = Color(0xFFF2C94C);
const _hongdaeBoulderOrangeColor = Color(0xFFF2994A);
const _hongdaeBoulderPurpleColor = Color(0xFF9B51E0);

const _hongdaeLeadGreenColor = Color(0xFF4CAF50);
const _hongdaeLeadBlueColor = Color(0xFF2E90FA);
const _hongdaeLeadBlackColor = Color(0xFF3A3A3F);

const _gangnamWhiteColor = Color(0xFFE8E8EA);
const _gangnamYellowColor = Color(0xFFF2C94C);
const _gangnamGreenColor = Color(0xFF4CAF50);
const _gangnamBlueColor = Color(0xFF2E90FA);
const _gangnamRedColor = Color(0xFFE53935);

final Map<String, GymDetail> mockGymDetails = {
  'seongsu': GymDetail(
    id: 'seongsu',
    name: '락클라임 성수',
    accent: AppColors.holdLime,
    gymType: GymType.boulder,
    businessHours: '평일 10:00–23:00 · 주말 10:00–22:00',
    address: '서울 성동구 성수동2가 123-45',
    hashtags: const ['#볼더링', '#초보환영', '#성수동'],
    photos: const [AppColors.holdLime, AppColors.holdLime, AppColors.holdLime],
    pricePlans: const [
      PricePlan(label: '1일 체험권', price: '15,000원'),
      PricePlan(label: '1개월 정기권', price: '120,000원'),
      PricePlan(label: '3개월 정기권', price: '320,000원'),
    ],
    boulderDifficultySystem: const [
      DifficultyLevel(label: '초급 · 그린', color: _seongsuGreenColor),
      DifficultyLevel(label: '중급 · 블루', color: _seongsuBlueColor),
      DifficultyLevel(label: '고급 · 레드', color: _seongsuRedColor),
      DifficultyLevel(label: '전문가 · 블랙', color: _seongsuBlackColor),
    ],
    sectors: [
      Sector(
        id: 'a',
        name: 'A구역 · 슬랩',
        description: '수직·슬랩 위주',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p1',
            grade: 'V2',
            tapeColor: _seongsuGreenColor,
            setter: '지환',
            setDate: '8/1',
          ),
          ClimbingProblem(
            id: 'p2',
            grade: 'V3',
            tapeColor: _seongsuGreenColor,
            setter: '지환',
            setDate: '8/1',
          ),
          ClimbingProblem(
            id: 'p3',
            grade: 'V5',
            tapeColor: _seongsuBlueColor,
            setter: '수아',
            setDate: '8/1',
          ),
          ClimbingProblem(
            id: 'p4',
            grade: 'V7',
            tapeColor: _seongsuRedColor,
            setter: '민준',
            setDate: '7/28',
          ),
        ],
      ),
      Sector(
        id: 'b',
        name: 'B구역 · 오버행',
        description: '오버행 위주',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p5',
            grade: 'V4',
            tapeColor: _seongsuBlueColor,
            setter: '수아',
            setDate: '8/1',
          ),
          ClimbingProblem(
            id: 'p6',
            grade: 'V6',
            tapeColor: _seongsuRedColor,
            setter: '민준',
            setDate: '7/28',
          ),
          ClimbingProblem(
            id: 'p7',
            grade: 'V9',
            tapeColor: _seongsuBlackColor,
            setter: '하늘',
            setDate: '7/20',
          ),
        ],
      ),
      Sector(
        id: 'c',
        name: 'C구역 · 챌린지 월',
        description: '월간 챌린지 전용',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p8',
            grade: 'V8',
            tapeColor: _seongsuBlackColor,
            setter: '하늘',
            setDate: '7/15',
          ),
          ClimbingProblem(
            id: 'p9',
            grade: 'V10',
            tapeColor: _seongsuBlackColor,
            setter: '하늘',
            setDate: '7/15',
          ),
        ],
      ),
    ],
  ),
  'hongdae': GymDetail(
    id: 'hongdae',
    name: '그립하우스 홍대',
    accent: AppColors.holdMagenta,
    gymType: GymType.both,
    businessHours: '매일 11:00–24:00',
    address: '서울 마포구 동교동 12-3',
    hashtags: const ['#볼더링', '#리드', '#신규셋팅', '#홍대입구'],
    photos: const [
      AppColors.holdMagenta,
      AppColors.holdMagenta,
      AppColors.holdMagenta,
    ],
    pricePlans: const [
      PricePlan(label: '1일 체험권', price: '18,000원'),
      PricePlan(label: '1개월 정기권', price: '130,000원'),
    ],
    boulderDifficultySystem: const [
      DifficultyLevel(label: '초급 · 옐로우', color: _hongdaeBoulderYellowColor),
      DifficultyLevel(label: '중급 · 오렌지', color: _hongdaeBoulderOrangeColor),
      DifficultyLevel(label: '고급 · 퍼플', color: _hongdaeBoulderPurpleColor),
    ],
    leadDifficultySystem: const [
      DifficultyLevel(label: '초급 · 그린', color: _hongdaeLeadGreenColor),
      DifficultyLevel(label: '중급 · 블루', color: _hongdaeLeadBlueColor),
      DifficultyLevel(label: '고급 · 블랙', color: _hongdaeLeadBlackColor),
    ],
    sectors: [
      Sector(
        id: 'main',
        name: '메인 월',
        description: '가장 넓은 볼더링 구역',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p1',
            grade: 'V1',
            tapeColor: _hongdaeBoulderYellowColor,
            setter: '태윤',
            setDate: '8/3',
          ),
          ClimbingProblem(
            id: 'p2',
            grade: 'V3',
            tapeColor: _hongdaeBoulderYellowColor,
            setter: '태윤',
            setDate: '8/3',
          ),
          ClimbingProblem(
            id: 'p3',
            grade: 'V5',
            tapeColor: _hongdaeBoulderOrangeColor,
            setter: '태윤',
            setDate: '8/3',
          ),
          ClimbingProblem(
            id: 'p4',
            grade: 'V7',
            tapeColor: _hongdaeBoulderPurpleColor,
            setter: '서연',
            setDate: '7/30',
          ),
        ],
      ),
      Sector(
        id: 'lead',
        name: '리드 월',
        description: '로프 리드 클라이밍',
        discipline: ClimbingDiscipline.lead,
        problems: const [
          ClimbingProblem(
            id: 'p5',
            grade: '5.10a',
            tapeColor: _hongdaeLeadGreenColor,
            setter: '서연',
            setDate: '7/30',
          ),
          ClimbingProblem(
            id: 'p6',
            grade: '5.11c',
            tapeColor: _hongdaeLeadBlueColor,
            setter: '서연',
            setDate: '7/30',
          ),
          ClimbingProblem(
            id: 'p7',
            grade: '5.12b',
            tapeColor: _hongdaeLeadBlackColor,
            setter: '서연',
            setDate: '7/30',
          ),
        ],
      ),
      Sector(
        id: 'kids',
        name: '키즈 존',
        description: '어린이 전용 낮은 벽',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p8',
            grade: 'V0',
            tapeColor: _hongdaeBoulderYellowColor,
            setter: '태윤',
            setDate: '8/3',
          ),
        ],
      ),
    ],
  ),
  'gangnam': GymDetail(
    id: 'gangnam',
    name: '볼더베이스 강남',
    accent: AppColors.holdCyan,
    gymType: GymType.boulder,
    businessHours: '24시간 운영',
    address: '서울 강남구 역삼동 45-6',
    hashtags: const ['#볼더링', '#24시간', '#강남역'],
    photos: const [AppColors.holdCyan, AppColors.holdCyan, AppColors.holdCyan],
    pricePlans: const [
      PricePlan(label: '1일 체험권', price: '20,000원'),
      PricePlan(label: '1개월 정기권', price: '150,000원'),
    ],
    boulderDifficultySystem: const [
      DifficultyLevel(label: '입문 · 화이트', color: _gangnamWhiteColor),
      DifficultyLevel(label: '초급 · 옐로우', color: _gangnamYellowColor),
      DifficultyLevel(label: '중급 · 그린', color: _gangnamGreenColor),
      DifficultyLevel(label: '고급 · 블루', color: _gangnamBlueColor),
      DifficultyLevel(label: '전문가 · 레드', color: _gangnamRedColor),
    ],
    sectors: [
      Sector(
        id: '1f',
        name: '1층 볼더링',
        description: '입문~중급',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p1',
            grade: 'V0',
            tapeColor: _gangnamWhiteColor,
            setter: '하늘',
            setDate: '8/5',
          ),
          ClimbingProblem(
            id: 'p2',
            grade: 'V2',
            tapeColor: _gangnamYellowColor,
            setter: '하늘',
            setDate: '8/5',
          ),
          ClimbingProblem(
            id: 'p3',
            grade: 'V4',
            tapeColor: _gangnamGreenColor,
            setter: '민준',
            setDate: '8/2',
          ),
        ],
      ),
      Sector(
        id: '2f',
        name: '2층 볼더링',
        description: '중급~고급',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p4',
            grade: 'V6',
            tapeColor: _gangnamBlueColor,
            setter: '민준',
            setDate: '8/2',
          ),
          ClimbingProblem(
            id: 'p5',
            grade: 'V8',
            tapeColor: _gangnamRedColor,
            setter: '민준',
            setDate: '8/2',
          ),
        ],
      ),
      Sector(
        id: 'roof',
        name: '루프 구간',
        description: '천장 구간 전문가용',
        discipline: ClimbingDiscipline.boulder,
        problems: const [
          ClimbingProblem(
            id: 'p6',
            grade: 'V9',
            tapeColor: _gangnamRedColor,
            setter: '민준',
            setDate: '7/29',
          ),
        ],
      ),
    ],
  ),
};
