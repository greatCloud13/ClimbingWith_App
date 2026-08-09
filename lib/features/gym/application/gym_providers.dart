import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/gym_api.dart';
import '../domain/gym_detail.dart';

final Provider<GymApi> gymApiProvider = Provider<GymApi>(
  (ref) => GymApi(ref.watch(dioClientProvider).dio),
);

/// 실제 gymId(정수)로 GET /api/gym/{id}를 호출한다. 목업 암장(문자열 id)에는 쓰이지 않는다.
final gymDetailProvider = FutureProvider.family<GymDetail, int>(
  (ref, id) => ref.watch(gymApiProvider).fetchGymDetail(id),
);
