import 'climbing_discipline.dart';
import 'climbing_problem.dart';

class Sector {
  const Sector({
    required this.id,
    required this.name,
    required this.description,
    required this.discipline,
    required this.problems,
  });

  final String id;
  final String name;
  final String description;
  final ClimbingDiscipline discipline;
  final List<ClimbingProblem> problems;
}
