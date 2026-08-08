/// 환경별 설정값. 빌드 타임에 `--dart-define`으로 주입한다 (백엔드의 .env에 대응).
///
/// 예)
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080
///   flutter build apk --dart-define=API_BASE_URL=https://api.climbingwith.app
///
/// 값을 소스에 하드코딩하지 않기 위해 dart-define을 쓴다 — 런타임에 .env 파일을
/// 읽는 방식(flutter_dotenv)도 가능하지만, 모바일 빌드에 평문 설정 파일을
/// 번들링하지 않아도 되고 컴파일 타임에 값이 고정되어 실수로 잘못된 서버를
/// 바라볼 위험이 적은 이 방식을 기본으로 채택한다.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
