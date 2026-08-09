/// GET /api/home 응답 항목 — 로그인 사용자가 북마크한 암장 카드 + 암장별 최근 공지.
class HomeNoticeSummary {
  const HomeNoticeSummary({
    required this.postId,
    required this.noticeTitle,
    required this.date,
  });

  final int postId;
  final String noticeTitle;
  final String date;

  factory HomeNoticeSummary.fromJson(Map<String, dynamic> json) =>
      HomeNoticeSummary(
        postId: json['postId'] as int,
        noticeTitle: json['noticeTitle'] as String,
        date: json['date'] as String,
      );
}

class HomeGymCard {
  const HomeGymCard({
    required this.gymId,
    required this.gymName,
    required this.address,
    required this.imageUrl,
    required this.notices,
    this.bookmarkId,
  });

  final int gymId;
  final String gymName;
  final String address;
  final String? imageUrl;
  final List<HomeNoticeSummary> notices;

  /// 이 암장 북마크(즐겨찾기) 자체의 id — 해제(DELETE /api/bookmark/{id})에 필요.
  final int? bookmarkId;

  factory HomeGymCard.fromJson(Map<String, dynamic> json) => HomeGymCard(
    gymId: json['gymId'] as int,
    gymName: json['gymName'] as String,
    address: json['address'] as String,
    imageUrl: json['imageUrl'] as String?,
    bookmarkId: json['bookmarkId'] as int?,
    notices: (json['notices'] as List<dynamic>? ?? [])
        .map((e) => HomeNoticeSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
