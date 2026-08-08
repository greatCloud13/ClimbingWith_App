import '../../../core/theme/app_colors.dart';
import '../domain/friend_activity.dart';

/// 스트릭/친구활동 API가 아직 없어 임시로 목업한다.
/// 즐겨찾기 암장/공지는 GET /api/home으로 실제 연동됨 (home_providers.dart 참고).

/// 연속 방문일 등 스트릭 통계 — 완등 기록 API 연동 전까지 임시 목업.
const int mockStreakDays = 5;
const int mockMonthlyClimbCount = 12;

const List<FriendActivity> mockFriendActivities = [
  FriendActivity(
    friendNickname: '서연',
    gymName: '락클라임 성수',
    grade: 'V5',
    timeAgo: '10분 전',
    accent: AppColors.holdMagenta,
  ),
  FriendActivity(
    friendNickname: '태윤',
    gymName: '그립하우스 홍대',
    grade: 'V6',
    timeAgo: '32분 전',
    accent: AppColors.holdLime,
  ),
  FriendActivity(
    friendNickname: '하늘',
    gymName: '볼더베이스 강남',
    grade: 'V4',
    timeAgo: '1시간 전',
    accent: AppColors.holdCyan,
  ),
];
