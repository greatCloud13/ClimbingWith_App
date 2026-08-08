import '../../../core/theme/app_colors.dart';
import '../domain/favorite_gym.dart';
import '../domain/friend_activity.dart';
import '../domain/notice.dart';

/// 즐겨찾기/공지/스트릭/친구활동 API가 아직 없어 임시로 목업한다.
/// 실제 연동 시 이 파일을 지우고 provider로 교체.
///
/// 공지는 전역이 아니라 암장별로 종속된다 — 각 Notice는 특정 FavoriteGym에
/// 붙어서 그 암장 카드 안에 표시된다.
const Notice _noticeSeongsu = Notice(
  id: 'n1',
  title: '8월 신규 셋팅 안내',
  subtitle: '전 구역 리뉴얼',
  body: '락클라임 성수점 전 구역이 8월 첫째 주 신규 셋팅으로 교체됩니다. '
      '기존 완등 기록은 유지되며, 신규 루트는 앱 기록 화면에서 바로 확인하실 수 있습니다.',
  accent: AppColors.holdLime,
);

const Notice _noticeHongdae = Notice(
  id: 'n2',
  title: '포인트 적립 프로모션',
  subtitle: '첫 체크인 5,000P',
  body: '앱 런칭을 기념해 첫 체크인 시 5,000포인트를 드립니다. '
      '포인트는 이 암장 현장 결제에 바로 사용하실 수 있습니다.',
  accent: AppColors.holdMagenta,
);

const Notice _noticeGangnam = Notice(
  id: 'n3',
  title: '추석 연휴 운영시간 안내',
  subtitle: '9/16~9/18 단축 운영',
  body: '추석 연휴 기간(9/16~9/18) 단축 운영됩니다. 자세한 시간은 공지 전문을 확인해주세요.',
  accent: AppColors.holdCyan,
);

const List<Notice> mockNotices = [_noticeSeongsu, _noticeHongdae, _noticeGangnam];

const List<FavoriteGym> mockFavoriteGyms = [
  FavoriteGym(name: '락클라임 성수', area: '성수동', accent: AppColors.holdLime, notice: _noticeSeongsu),
  FavoriteGym(name: '그립하우스 홍대', area: '홍대입구', accent: AppColors.holdMagenta, notice: _noticeHongdae),
  FavoriteGym(name: '볼더베이스 강남', area: '강남역', accent: AppColors.holdCyan, notice: _noticeGangnam),
];

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
