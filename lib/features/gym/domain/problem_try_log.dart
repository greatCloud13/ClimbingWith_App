/// 문제 시도 기록. GET/PUT/DELETE /api/problemTryLog/{id}, POST /api/problemTryLog,
/// GET /api/problemTryLog/user/{userId} 응답.
class ProblemTryLog {
  const ProblemTryLog({
    required this.id,
    required this.userId,
    required this.problemId,
    required this.tryDate,
    required this.dropPoint,
    this.memo,
    this.isLocalOnly = false,
  });

  final int id;
  final int userId;
  final int problemId;

  /// 서버가 내려준 원본 문자열 그대로 보관 — 형식이 아직 확정되지 않아
  /// 화면에서는 [DateTime.tryParse]로 파싱해 쓴다.
  final String tryDate;

  /// 이 트라이에서 도달한 최고 지점(1-based 홀드 순번).
  final int dropPoint;

  final String? memo;

  /// true면 서버에 저장되지 않은 게스트 체험 모드 기록 — 세션(화면) 밖에서는 사라진다.
  final bool isLocalOnly;

  DateTime? get tryDateTime => DateTime.tryParse(tryDate);

  factory ProblemTryLog.fromJson(Map<String, dynamic> json) => ProblemTryLog(
    id: json['id'] as int,
    userId: json['userId'] as int,
    problemId: json['problemId'] as int,
    tryDate: json['tryDate'] as String,
    dropPoint: json['dropPoint'] as int,
    memo: json['memo'] as String?,
  );
}

/// GET /api/problemTryLog/user/{userId} 페이지 응답.
class ProblemTryLogPage {
  const ProblemTryLogPage({required this.logs, required this.pageNumber, required this.isLast});

  final List<ProblemTryLog> logs;
  final int pageNumber;
  final bool isLast;

  factory ProblemTryLogPage.fromJson(Map<String, dynamic> json) => ProblemTryLogPage(
    logs: (json['content'] as List<dynamic>)
        .map((e) => ProblemTryLog.fromJson(e as Map<String, dynamic>))
        .toList(),
    pageNumber: json['number'] as int,
    isLast: json['last'] as bool,
  );
}
