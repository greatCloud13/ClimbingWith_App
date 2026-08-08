import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/token_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// onUnauthorized 콜백은 실제 401 발생 시점(빌드가 끝난 뒤)에만 호출되므로
/// authControllerProvider를 여기서 읽어도 순환 빌드 문제가 생기지 않는다.
/// (단, 변수 자체에 타입을 명시하지 않으면 Dart 최상위 타입 추론이 서로
/// 참조하는 provider들을 순환으로 오판하므로 아래처럼 타입을 모두 명시한다.)
final Provider<DioClient> dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(authControllerProvider.notifier).forceLogout(),
  );
});

final Provider<AuthApi> authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.watch(dioClientProvider).dio));

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
