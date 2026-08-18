/// 완등 기록. POST/PATCH(.../clear)/PUT/DELETE `/api/clearRecord`(/{id}) 응답.
/// "트라이 시작"을 누르면 `isClear=false`/`startDate=오늘`/`clearDate=null`로
/// 생성되고, 완등하면 `PATCH /api/clearRecord/{id}/clear`로 `isClear=true`와
/// `clearDate`가 채워진다. 개별 낙하 지점 기록([ProblemTryLog](problem_try_log.dart))과는
/// 별개로, "이 문제를 언제부터 도전해서 언제 완등했는지"만 담당한다.
class ClearRecord {
  const ClearRecord({
    required this.id,
    required this.username,
    required this.settingId,
    required this.problemId,
    required this.startDate,
    required this.isClear,
    this.videoUrl,
    this.clearDate,
  });

  final int id;
  final String username;
  final int settingId;
  final int problemId;
  final String startDate;
  final bool isClear;
  final String? videoUrl;
  final String? clearDate;

  factory ClearRecord.fromJson(Map<String, dynamic> json) => ClearRecord(
    id: json['id'] as int,
    username: json['username'] as String? ?? '',
    settingId: json['settingId'] as int,
    problemId: json['problemId'] as int,
    startDate: json['startDate'] as String? ?? '',
    // 서버가 `isClear` 필드를 `clear`로 직렬화해서 내려준다(Jackson의 is-접두 boolean 관례).
    isClear: json['clear'] as bool? ?? false,
    videoUrl: json['videoUrl'] as String?,
    clearDate: json['clearDate'] as String?,
  );
}
