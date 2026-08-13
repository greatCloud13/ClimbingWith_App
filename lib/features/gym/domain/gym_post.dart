/// GET /api/post/gym/{gymId}(/posttype/{postType}) 응답 항목.
class GymPost {
  const GymPost({
    required this.id,
    required this.title,
    required this.postType,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String postType;
  final DateTime createdAt;

  factory GymPost.fromJson(Map<String, dynamic> json) => GymPost(
    id: json['id'] as int,
    title: json['title'] as String,
    postType: json['postType'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class GymPostPage {
  const GymPostPage({
    required this.posts,
    required this.pageNumber,
    required this.isLast,
  });

  final List<GymPost> posts;
  final int pageNumber;
  final bool isLast;

  factory GymPostPage.fromJson(Map<String, dynamic> json) => GymPostPage(
    posts: (json['content'] as List<dynamic>)
        .map((e) => GymPost.fromJson(e as Map<String, dynamic>))
        .toList(),
    pageNumber: json['number'] as int,
    isLast: json['last'] as bool,
  );
}

/// GET/PUT/POST /api/post(/{postId}) 응답 — 게시글 상세(본문 포함).
class GymPostDetail {
  const GymPostDetail({
    required this.id,
    required this.title,
    required this.gymName,
    required this.writer,
    required this.postType,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String gymName;
  final String writer;
  final String postType;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory GymPostDetail.fromJson(Map<String, dynamic> json) => GymPostDetail(
    id: json['id'] as int,
    title: json['title'] as String,
    gymName: json['gymName'] as String? ?? '',
    writer: json['writer'] as String? ?? '',
    postType: json['postType'] as String,
    content: json['content'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.tryParse(json['updatedAt'] as String),
  );
}

/// 게시판 태그 필터. `null`은 "전체"(필터 없음)를 뜻한다.
const List<String?> gymPostTypeFilters = [
  null,
  'NOTICE',
  'SETTING_SCHEDULE',
  'LOST_ITEMS',
  'PROMOTION',
];

/// 글 작성/수정 폼에서 고르는 실제 postType 값 (필터의 "전체"는 제외).
const List<String> gymPostTypes = [
  'NOTICE',
  'SETTING_SCHEDULE',
  'LOST_ITEMS',
  'PROMOTION',
];

const Map<String, String> gymPostTypeLabels = {
  'NOTICE': '공지사항',
  'SETTING_SCHEDULE': '세팅 일정',
  'LOST_ITEMS': '분실물 안내',
  'PROMOTION': '암장 이벤트',
};

String gymPostTypeLabel(String? postType) =>
    postType == null ? '전체' : (gymPostTypeLabels[postType] ?? postType);
