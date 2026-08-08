import '../../../core/network/token_storage.dart';
import '../domain/current_user.dart';
import 'auth_api.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage tokenStorage})
    : _api = api,
      _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<String> signUp(SignUpRequest request) => _api.signUp(request);

  Future<CurrentUser> login(LoginRequest request) async {
    final response = await _api.login(request);
    final user = CurrentUser(
      username: response.username,
      nickname: response.nickname,
      role: response.role,
      managedGymId: response.managedGymId,
    );
    await _tokenStorage.saveSession(response.token, user);
    return user;
  }

  Future<void> logout() => _tokenStorage.clearSession();

  Future<CurrentUser?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    return _tokenStorage.readUser();
  }
}
