import 'gym_type.dart';

/// GET /api/gym/search 응답 항목.
class GymSearchResult {
  const GymSearchResult({
    required this.id,
    required this.gymName,
    required this.gymType,
    required this.address,
    required this.openAt,
    required this.closeAt,
    required this.weekendOpenAt,
    required this.weekendCloseAt,
    required this.isActive,
  });

  final int id;
  final String gymName;
  final GymType gymType;
  final String address;
  final String? openAt;
  final String? closeAt;
  final String? weekendOpenAt;
  final String? weekendCloseAt;
  final bool isActive;

  factory GymSearchResult.fromJson(Map<String, dynamic> json) =>
      GymSearchResult(
        id: json['id'] as int,
        gymName: json['gymName'] as String,
        gymType: GymType.fromApiValue(json['gymType'] as String),
        address: json['address'] as String,
        openAt: json['openAt'] as String?,
        closeAt: json['closeAt'] as String?,
        weekendOpenAt: json['weekendOpenAt'] as String?,
        weekendCloseAt: json['weekendCloseAt'] as String?,
        isActive: json['isActive'] as bool,
      );
}

class GymSearchResultPage {
  const GymSearchResultPage({
    required this.results,
    required this.pageNumber,
    required this.isLast,
  });

  final List<GymSearchResult> results;
  final int pageNumber;
  final bool isLast;

  factory GymSearchResultPage.fromJson(Map<String, dynamic> json) =>
      GymSearchResultPage(
        results: (json['content'] as List<dynamic>)
            .map((e) => GymSearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        pageNumber: json['number'] as int,
        isLast: json['last'] as bool,
      );
}
