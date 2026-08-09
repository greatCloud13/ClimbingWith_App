import 'climbing_discipline.dart';
import 'climbing_problem.dart';

class Sector {
  const Sector({
    required this.id,
    required this.name,
    required this.discipline,
    required this.problemCount,
    this.description,
    this.settingDate,
    this.nextSettingDate,
    this.problems = const [],
  });

  final String id;
  final String name;
  final ClimbingDiscipline discipline;

  /// 섹터의 문제 개수. 실제 문제 목록 API가 없는 경우(백엔드 연동 시) `problems`는
  /// 비어있을 수 있어 카운트 표시는 이 필드를 우선 쓴다.
  final int problemCount;
  final String? description;
  final String? settingDate;
  final String? nextSettingDate;
  final List<ClimbingProblem> problems;

  factory Sector.fromApiJson(
    Map<String, dynamic> json, {
    required ClimbingDiscipline discipline,
  }) {
    return Sector(
      id: (json['id'] as int).toString(),
      name: json['sectorName'] as String,
      discipline: discipline,
      problemCount: json['problemCount'] as int? ?? 0,
      description: json['description'] as String?,
      settingDate: json['settingDate'] as String?,
      nextSettingDate: json['nextSettingDate'] as String?,
    );
  }
}
