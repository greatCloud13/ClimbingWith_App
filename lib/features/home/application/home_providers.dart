import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/home_api.dart';
import '../domain/home_gym_card.dart';

final Provider<HomeApi> homeApiProvider = Provider<HomeApi>(
  (ref) => HomeApi(ref.watch(dioClientProvider).dio),
);

/// 게스트 상태에서는 호출되지 않는다 — HomeScreen이 로그인 상태일 때만 watch한다.
final FutureProvider<List<HomeGymCard>> homeGymCardsProvider =
    FutureProvider<List<HomeGymCard>>(
      (ref) => ref.watch(homeApiProvider).fetchHomeGymCards(),
    );
