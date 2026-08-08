# 클라이밍 커뮤니티 앱 (climbing_community_app)

클라이밍 커뮤니티 서버의 클라이언트 앱. Flutter 기반, 백엔드는 별도 위치에 이미 존재.

## 협업 규칙

1. 복잡한 프롬프트는 최종 답변 전에 단계별로 생각한다.
2. 나(Claude)는 앱 개발 부서의 수석 엔지니어 역할로 작업한다.
3. 디자인/구현 선택지를 제시할 때는 안전하고 전통적인 버전 하나와, 진짜 창의적인 위험을 감수하는 버전 하나를 함께 예시로 제공한다.
4. (버그/문제 상황에 한해) 응답 형식: `[문제] / [근본 원인] / [해결책] / [예방]`
5. 응답은 최대 3문장으로. 안 되면 5개 글머리 기호까지만 사용한다.
6. 서버는 거의 완성 상태로 별도 위치에 존재한다. 개발 중 필요한 API는 구체적으로 요청하면 제공받는 방식으로 진행한다. 아직 없는 API는 요청 후 구현되어 제공된다.
7. 다음 작업(특히 새 단계로 넘어가는 작업)은 진행 전에 먼저 보고하고 승인을 받는다.

## AI 티(AI-generated 느낌) 방지 원칙

AI가 만든 UI가 어색해 보이는 이유와 대응 방법을 프로젝트 전반에 적용한다.

- **레이아웃**: 2022~2023년식 3열 카드/거대 Hero 섹션/균일한 그라데이션 아이콘 같은 정형화된 구도를 피한다. 실제 데이터(한국어 텍스트, 가변 길이)를 기준으로 레이아웃을 설계한다.
- **스타일**: 보라-파랑 계열의 몽환적 그라데이션, 남용된 유리질감(Glassmorphism), 브랜드와 무관한 3D 아이콘을 기본값으로 쓰지 않는다. 이 프로젝트는 대신 클라이밍 도메인에서 나온 모티프(홀드 컬러, 크래시 매트 스티치 패턴)를 사용한다.
- **UX 디테일**: 로딩/빈 상태(Empty State)/에러/입력 길이 초과 등 예외 상태를 명시적으로 설계한다 (현재 프로토타입은 해피 패스만 구현됨 — 후속 작업 필요).
- **접근성**: 명도 대비와 터치 영역 크기를 가이드라인에 맞춘다.
- **코드**: Tailwind류 하드코딩 클래스 남발 금지, 공통 컴포넌트로 재사용성 확보. 디자인 토큰(`lib/core/theme`)만 참조하고 임의 색상값을 인라인으로 새로 만들지 않는다.
- **데이터**: 더미/lorem ipsum 대신 실제 서비스에 들어갈 법한 한국어 텍스트로 목업한다 (완등 후기, 짐 이름 등).

## 디자인 컨셉 — 채택: 창의적 버전

다크 베이스 + 클라이밍 홀드 컬러 액센트. "체육관 조명 아래 크래시 매트" 무드.

- **컬러 토큰**: [app_colors.dart](lib/core/theme/app_colors.dart)
  - 배경 `#0B0B0D`, 서피스 `#17171B` / `#1F1F24`, 보더 `#2A2A30`
  - 홀드 액센트: 라임 `#D4FF3D`, 마젠타 `#FF3B7F`, 시안 `#3DD6FF` (남발 금지, 포인트에만)
  - 난이도(V등급) 색: easy 초록 → mid 라임 → hard 마젠타 → extreme 빨강
- **타이포그래피**: [app_typography.dart](lib/core/theme/app_typography.dart)
  - 헤드라인: `BlackHanSans` (포스터 느낌 굵은 고딕) — 헤드라인 전용, 본문/버튼에는 쓰지 않음
  - 본문: `NotoSansKR` (400/500/700)
  - 두 폰트 모두 `assets/fonts/`에 로컬 번들링 (Korean subset TTF). 초기에 `google_fonts` 패키지로 런타임 네트워크 페치를 시도했으나 웹 프리뷰 환경에서 요청 자체가 발생하지 않아 한글이 tofu box로 렌더링되는 문제가 있었음 → 네트워크 의존을 없애기 위해 로컬 asset 번들링으로 전환, 확인 완료. `pubspec.yaml`의 `flutter.fonts` 섹션 참고.
- **텍스처**: [mat_texture_background.dart](lib/core/widgets/mat_texture_background.dart) — 크래시 패드 다이아몬드 스티치 패턴을 낮은 명도차로 그려 넣은 배경 (그라데이션 블러 대신 도메인 모티프 사용)

## 기술 스택

- **Flutter** (SDK ^3.10.7), Material 3, 다크 테마 고정
- **상태관리**: `flutter_riverpod` ^2.6.1 — 인증 플로우부터 실제 provider 연결 시작 (`StateNotifierProvider` 패턴, codegen 없이 수동 작성)
- **네트워킹**: `dio` ^5.7.0 — 인증 토큰 자동 첨부 + 401 인터셉터
- **보안 저장소**: `flutter_secure_storage` ^9.2.2 — AccessToken/로그인 사용자 정보 보관 (Keychain/Keystore, 평문 저장 아님)
- **환경설정**: `--dart-define`으로 API base URL 주입 (백엔드 `.env`에 대응). 기본값 `http://localhost:8080`. `flutter run --dart-define=API_BASE_URL=https://...`로 오버라이드. [app_config.dart](lib/core/config/app_config.dart) 참고 — 대안으로 `flutter_dotenv` 런타임 방식도 있으나, 모바일 앱에 평문 설정 파일을 번들링하지 않아도 되고 실수로 잘못된 서버를 바라볼 위험이 적은 dart-define을 기본 채택
- **라우팅**: `go_router` ^14.6.2 (의존성만 추가됨, 현재는 `IndexedStack` 기반 바텀 네비게이션으로 단순 구현 — 화면이 늘어나면 go_router로 전환)
- **폰트**: 로컬 번들 TTF (`assets/fonts/`), 네트워크 페치 없음

## 폴더 구조 (feature-first)

```
lib/
  core/
    config/          # app_config.dart — 환경설정 (API base URL 등)
    network/         # dio_client.dart, token_storage.dart, api_exception.dart
    theme/           # app_colors.dart, app_typography.dart, app_theme.dart — 디자인 토큰, 여기만 참조
    widgets/         # mat_texture_background.dart, grade_badge.dart 등 공용 위젯
  features/
    auth/
      data/          # auth_api.dart, auth_models.dart, auth_repository.dart
      domain/        # current_user.dart
      application/   # auth_state.dart, auth_controller.dart, auth_providers.dart
      presentation/  # login_screen.dart, signup_screen.dart
    feed/            # feed_screen.dart — 커뮤니티 피드
    gym/             # gym_screen.dart — 클라이밍장/루트 정보
    record/          # record_screen.dart — 완등 기록/랭킹
    shell/           # app_shell.dart — 바텀 네비게이션 셸
  main.dart          # ProviderScope + AuthGate (로그인 상태에 따라 LoginScreen ↔ AppShell 전환)
```

## 인증 (구현 완료)

- **API**: `POST /api/auth/signup` `{username, nickname, email, password}` → `{message}` / `POST /api/auth/login` `{username, password}` → `{token, username, role, nickname, managedGymId}`
- **유효성 검증**: 백엔드 DTO 제약과 동일하게 클라이언트에서도 검증 — username/nickname 4~20자, password 8~20자, email 형식
- **세션 저장**: 로그인 성공 시 토큰 + 사용자 정보(username/nickname/role/managedGymId)를 `flutter_secure_storage`에 함께 저장. **주의**: 백엔드에 세션 복원용 "내 정보 조회"(`/api/auth/me` 등) API가 아직 없어서, 앱 재시작 시 로그인 응답에서 받은 사용자 정보를 그대로 복원하는 방식으로 구현함 (네트워크 재검증 없음). 저장된 토큰이 실제로는 만료됐더라도 앱은 우선 로그인된 것처럼 보여주고, 이후 첫 인증 필요 API 호출이 401을 받으면 그때 강제 로그아웃된다. `/api/auth/me`가 생기면 앱 시작 시 그 API로 세션을 검증하는 방식으로 교체 권장.
- **토큰 만료**: 만료시간 필드가 아직 확정되지 않아 클라이언트에서 만료를 미리 계산하지 않음. 모든 인증 필요 요청은 `DioClient`가 토큰을 자동 첨부하고, 401 응답을 받으면 인터셉터가 세션을 지우고 로그인 화면으로 돌려보낸다.
- **에러 메시지**: 백엔드의 유효성 검증 실패 응답 포맷이 미확정이라 [api_exception.dart](lib/core/network/api_exception.dart)에서 `message`/`error`/`errors[].defaultMessage` 등 알려진 형태를 순서대로 시도하고, 실패하면 상태코드 기반 기본 메시지로 대체함. **실제 에러 응답 포맷이 확정되면 이 파서를 업데이트해야 함.**
- **로그아웃**: 피드 화면 상단 아이콘에 임시로 배치 (추후 프로필/설정 화면으로 이동 예정)

## 남은 작업 순서

1. ~~인증~~ (완료)
2. go_router 전환 (화면이 늘어나기 전에 `IndexedStack` → 라우팅 기반으로 교체)
3. 화면별 API 연동 — 클라이밍장 → 피드 → 기록 순, 로딩/에러/빈 상태 포함
4. 테스트/CI + 배포 설정

## 백엔드 연동 방식

백엔드 서버는 이 레포 밖 별도 위치에 이미 존재 (Spring Boot, 로컬 개발 중 `localhost:8080`). 화면 구현 중 특정 API가 필요해지는 시점에 사용자에게 개별 요청 → 제공받아 연동. 없는 API는 요청 후 구현되어 제공됨.

## 실행 방법

```bash
flutter pub get
flutter run -d chrome        # 또는 -d web-server --web-port <port>
flutter analyze
flutter test
```
