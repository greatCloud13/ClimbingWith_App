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
8. 백엔드 버그/API 요청사항은 CLAUDE.md에 적지 않고 `reports/YYYY-MM-DD_설명.md` 형태의 별도 보고서 파일로 제출한다 (2026-08-08부터 적용). CLAUDE.md는 확정된 사실만 기록.
9. 화면 디자인/레이아웃은 사용자가 직접 설계한다. 사용자가 레퍼런스(이미지 등)와 함께 구체적인 스펙을 주면 그 스펙대로 구현하고, 스펙에 없는 요소를 임의로 추가하지 않는다. 화면 관련 버그/이슈도 사용자가 해결 후 보고하면 그때 반영한다.

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
- **라우팅**: `go_router` ^14.6.2 — `StatefulShellRoute.indexedStack`으로 바텀탭 3개(`/feed`,`/gym`,`/record`) 구성, 인증 상태(`AuthChecking`/`Unauthenticated`/`Authenticated`)에 따라 `/splash`·`/login`·`/feed`로 자동 리다이렉트. [app_router.dart](lib/core/router/app_router.dart)
- **폰트**: 로컬 번들 TTF (`assets/fonts/`), 네트워크 페치 없음

## 폴더 구조 (feature-first)

```
lib/
  core/
    config/          # app_config.dart — 환경설정 (API base URL 등)
    network/         # dio_client.dart, token_storage.dart, api_exception.dart
    router/          # app_router.dart — go_router 라우트 정의 + 인증 리다이렉트
    theme/           # app_colors.dart, app_typography.dart, app_theme.dart — 디자인 토큰, 여기만 참조
    widgets/         # mat_texture_background.dart, grade_badge.dart 등 공용 위젯
  features/
    auth/
      data/          # auth_api.dart, auth_models.dart, auth_repository.dart
      domain/        # current_user.dart
      application/   # auth_state.dart, auth_controller.dart, auth_providers.dart
      presentation/  # login_screen.dart, signup_screen.dart
    feed/            # feed_screen.dart — 커뮤니티 피드 (현재 라우팅 미연결, 보류)
    gym/             # gym_screen.dart — 클라이밍장/루트 정보
    gym_manage/      # gym_manage_screen.dart — GYM_MANAGER 전용 (최소 구현)
    home/
      data/          # home_mock_data.dart — 즐겨찾기/공지 목업
      domain/        # notice.dart, favorite_gym.dart
      presentation/  # home_screen.dart, notice_detail_screen.dart
    more/            # more_screen.dart (최소 구현)
    profile/         # profile_screen.dart (최소 구현, 로그아웃 포함)
    record/          # record_screen.dart — 완등 기록/랭킹
    shell/           # app_shell.dart, splash_screen.dart, record_or_manage_screen.dart
  main.dart          # ProviderScope + MaterialApp.router
```

## 인증 (구현 완료)

- **API**: `POST /api/auth/signup` `{username, nickname, email, password}` → `{message}` / `POST /api/auth/login` `{username, password}` → `{token, username, role, nickname, managedGymId}`
- **유효성 검증**: 백엔드 DTO 제약과 동일하게 클라이언트에서도 검증 — username/nickname 4~20자, password 8~20자, email 형식
- **세션 저장**: 로그인 성공 시 토큰 + 사용자 정보(username/nickname/role/managedGymId)를 `flutter_secure_storage`에 함께 저장. **주의**: 백엔드에 세션 복원용 "내 정보 조회"(`/api/auth/me` 등) API가 아직 없어서, 앱 재시작 시 로그인 응답에서 받은 사용자 정보를 그대로 복원하는 방식으로 구현함 (네트워크 재검증 없음). 저장된 토큰이 실제로는 만료됐더라도 앱은 우선 로그인된 것처럼 보여주고, 이후 첫 인증 필요 API 호출이 401을 받으면 그때 강제 로그아웃된다. `/api/auth/me`가 생기면 앱 시작 시 그 API로 세션을 검증하는 방식으로 교체 권장.
  - 보안 저장소 쓰기가 실패해도(플랫폼별 Keystore 이슈 등) 로그인 자체(홈 화면 이동)는 막지 않도록 처리함 ([auth_repository.dart](lib/features/auth/data/auth_repository.dart)) — 저장 실패 시 다음 앱 실행 때 재로그인이 필요할 수 있음
- **Android cleartext 이슈**: 백엔드가 아직 HTTP(`http://localhost:8080`)라서 Android 9(API 28)+ 기본 정책상 요청이 조용히 막힘 → `AndroidManifest.xml`에 `android:usesCleartextTraffic="true"` 추가함 (2026-08-08). 백엔드가 HTTPS로 바뀌면 제거 가능.
- **토큰 만료**: 만료시간 필드가 아직 확정되지 않아 클라이언트에서 만료를 미리 계산하지 않음. 모든 인증 필요 요청은 `DioClient`가 토큰을 자동 첨부하고, 401 응답을 받으면 인터셉터가 세션을 지우고 로그인 화면으로 돌려보낸다.
- **에러 메시지**: 에러 응답 포맷은 `{success, data, error: {code, message}}`로 실제 백엔드 호출로 확인 완료 (성공 응답은 래핑 없이 flat — 예: 로그인 성공 시 `{token, username, role, nickname, managedGymId}` 그대로). [api_exception.dart](lib/core/network/api_exception.dart)에서 `error.message`를 우선 사용하고, 혹시 모를 다른 포맷(`message`, `errors[].defaultMessage`)도 폴백으로 시도함.
- **로그아웃**: 프로필 화면으로 이동 배치
- **CORS**: 로컬 개발 시 Flutter 웹(`localhost:8765`)과 Spring 백엔드(`localhost:8080`)가 다른 origin이라 백엔드에 CORS 허용 설정이 필요함 (2026-08-08 백엔드에 추가 완료, 확인함). 모바일 빌드에는 해당 없음(CORS는 브라우저 전용 정책).

> **백엔드에 요청/보고가 필요한 사항은 이 문서가 아니라 [`reports/`](reports/) 아래 날짜별 보고서 파일로 관리한다.** CLAUDE.md는 확정된 사실만 기록.

## 네비게이션 구조 (5탭) + 게스트 접근

바텀탭: 홈 / 암장 / 운동기록(또는 암장관리) / 프로필 / 더보기. 4번째 탭은 `CurrentUser.role`이 `GYM_MANAGER`면 "암장관리"(`GymManageScreen`)로, 그 외엔 "운동기록"(`RecordScreen`)으로 내용과 라벨·아이콘이 함께 바뀐다 — 경로(`/record`)는 고정, [record_or_manage_screen.dart](lib/features/shell/record_or_manage_screen.dart)에서 분기.

**로그인 없이도 앱 사용 가능(게스트 모드)**: 앱을 켰을 때 첫 화면은 로그인이 아니라 홈이다. `/profile`, `/record`만 로그인을 요구하고(`_authRequiredPaths`, [app_router.dart](lib/core/router/app_router.dart)), `/home`·`/gym`·`/more`는 게스트도 접근 가능. 홈 화면 안에서 개인화 섹션(즐겨찾기 클라이밍장/스트릭/친구활동)은 로그인 상태일 때만 보이고, 비로그인 시 그 자리에 로그인 유도 카드(`_GuestPromptCard`)가 대신 표시된다.

- `/home` — [home_screen.dart](lib/features/home/presentation/home_screen.dart): "오늘은 어느 암장으로 가실건가요?" 헤더 + 알림 버튼(공개). 로그인 시에만: 연속방문 스트릭 카드, 친구 활동 가로 카드, 그리고 즐겨찾기 클라이밍장 **세로 피드** — 카드 하나가 [암장이름 + 메인 사진 + 그 암장에 종속된 공지]로 구성됨. **공지는 전역이 아니라 암장별로 붙는다** — 처음엔 전역 공지 슬라이드로 잘못 구현했다가 사용자 와이어프레임을 받고 암장별 종속 구조로 재작업함.
  - **즐겨찾기 암장 + 공지는 실제 API 연동 완료**: `GET /api/home` → `{gymCardList: [{gymId, gymName, address, imageUrl, notices: [{postId, noticeTitle, date}]}]}` (토큰 기반, 파라미터 없음, 공지 최대 5개). [home_api.dart](lib/features/home/data/home_api.dart) / [home_providers.dart](lib/features/home/application/home_providers.dart)에서 `homeGymCardsProvider`(FutureProvider)로 로딩/에러/빈 상태까지 처리. 카드당 공지는 `_GymNoticeCarousel`이 5초 간격으로 자동 슬라이드하며 전부 보여줌 (수동 스와이프로도 넘길 수 있음) — 공지가 1개뿐이면 슬라이드 없이 고정. 공지 상세는 아직 본문 API가 없어 안내 문구로 대체.
  - 로그아웃 상태 또는 북마크한 암장이 없는 경우 둘 다 "등록된 암장 리스트 보기" 버튼으로 `/gym`으로 안내 (`_GuestPromptCard`, `_EmptyGymBookmarksCard`)
  - 스트릭/친구활동은 아직 API 없어 목업 데이터 사용 중 (`reports/` 참고)
- `/gym`, `/record` — 기존 GymScreen/RecordScreen 재사용
- `/profile`, `/more` — 최소 구현 (상세 디자인은 사용자가 별도 설계 예정)
- 기존 `FeedScreen`(커뮤니티 피드, [feed_screen.dart](lib/features/feed/feed_screen.dart))은 5탭 구성에서 빠져 현재 라우팅에 연결되어 있지 않음 — 삭제하지 않고 보류 (재사용 여부 확인 필요)

## 암장 상세 / 섹터 / 문제 리스트

홈의 즐겨찾기 카드, 암장 목록(`/gym`)의 카드 모두 같은 `gymId`로 `/gym/:id`(상세)로 연결된다. 상세에서 섹터를 탭하면 `/gym/:id/sector/:sectorId`(문제 리스트)로 이동.

- [gym_detail_screen.dart](lib/features/gym/presentation/gym_detail_screen.dart): 사진 갤러리(좌우 스와이프, `_GymPhotoGallery`), 우측 상단 즐겨찾기(별) · 알림구독(종) 토글, 로고, 영업시간, 주소, [길찾기(스텁)][가격보기] 버튼 나란히 — 이용권(`PricePlan`)은 상시 노출 대신 "가격보기" 탭 시 바텀시트로 표시, 해시태그, **난이도 체계**, 섹터 리스트
- **암장 종류(`GymType`: boulder/lead/both, 백엔드 enum과 대응)에 따라 난이도 체계 표시 방식이 다르다** ([gym_type.dart](lib/features/gym/domain/gym_type.dart)):
  - `boulder`: 색 스트립만 (`_BoulderLevelStrip`) — 왼쪽(쉬움) → 오른쪽(어려움), 암장마다 단계 수·색이 다름
  - `lead`: 기존 라벨+색 원형 리스트만 (`_LeadLevelList`)
  - `both`: 둘 다 갖고 있고 `_DifficultySection`에서 `PageView`로 좌우 스와이프 전환 (볼더/리드 표시 인디케이터 포함) — [gym_detail_mock_data.dart](lib/features/gym/data/gym_detail_mock_data.dart)에서 그립하우스 홍대가 `both` 예시
  - `GymDetail.boulderDifficultySystem` / `leadDifficultySystem`은 각각 `DifficultyLevel {label, color}` 리스트. 앱 공통 UI 컬러(AppColors.hold*)와는 별개 개념
  - 섹터도 `ClimbingDiscipline`(boulder/lead)을 가지며, `both` 암장의 섹터 리스트에는 볼더/리드 태그가 붙는다
- [sector_problems_screen.dart](lib/features/gym/presentation/sector_problems_screen.dart): 섹터 안 문제(`ClimbingProblem`) 리스트 — 등급, 테이프 색, 셋터, 셋팅일
- 알림구독, 길찾기 버튼은 로컬 state·스텁뿐 (API·지도 연동 없음, 새로고침 시 초기화) — `reports/` 참고
- **암장 상세는 `GET /api/gym/{id}` 실제 연동 완료 (2026-08-09)**: `id`가 정수로 파싱되면 이 API로 실데이터를 가져오고, 그 외(목업 문자열 id)는 기존 `mockGymDetails`를 그대로 씀 — `/gym` 탭(암장 목록)이 아직 전부 목업이라 그 화면에서 넘어오는 id와 실제 백엔드 id가 섞여있어 두 경로를 함께 유지 중. 이 API에는 이용권/난이도체계/섹터별 종목/문제 목록이 없어서, 데이터가 없으면 해당 섹션을 숨기거나 안내 문구로 대체함(가짜 데이터로 채우지 않음).
- **즐겨찾기(북마크) 실연동 완료 (2026-08-10)**: `POST /api/bookmark/{gymId}` → `{id, gymName}`(이 `id`는 북마크 자체의 id, gymId 아님) / `DELETE /api/bookmark/{id}`. 화면 진입 시 초기 별 채움 여부는 홈 즐겨찾기 목록(`GET /api/home`)에 이 암장이 있는지로 판단(`_resolveFavorite`, 로그인 상태에서만 조회).
  - **해제(DELETE)용 북마크 id 확보**: `GET /api/home`의 `gymCardList[]`에 `bookmarkId` 필드가 직접 추가됨(처음엔 별도 `bookmarkIdList`를 위치로 대응시켰다가, 1:1이 아니어서 명시적 필드로 교체함) — `HomeGymCard.bookmarkId`. 이번 세션에 앱에서 직접 등록한 건 `bookmarkIdMapProvider`, 그 외(이전부터 즐겨찾기된 암장)는 이 필드로 해제 가능.
- **게시판 (2026-08-09)**: 암장 상세의 "게시판" 버튼 → `/gym/:id/board` ([gym_board_screen.dart](lib/features/gym/presentation/gym_board_screen.dart)). 처음 진입 시 전체 게시글(`GET /api/post/gym/{gymId}`), 상단 태그(전체/공지사항/세팅 일정/분실물 안내/암장 이벤트) 선택 시 서버 필터링 조회(`GET /api/post/gym/{gymId}/posttype/{postType}` — 경로 세그먼트가 `postType`이 아니라 소문자 `posttype`이니 주의). 둘 다 페이지네이션("더 보기"). 목업 암장에는 버튼이 안 보임. 게시글 탭 시 기존 `/notice/:id` 화면 재사용 (본문은 안내 문구로 대체 — 상세 API 없음).
- **CORS**: 백엔드가 `localhost:3000` origin만 허용하도록 설정됨 (2026-08-09) — 웹 프리뷰 포트를 8765 → 3000으로 맞춤 (`.claude/launch.json`).

## 남은 작업 순서

1. ~~인증~~ (완료)
2. ~~go_router 전환~~ (완료)
3. ~~5탭 구조 + 홈 화면 + 게스트 접근~~ (완료 — 상세 화면 디자인은 사용자 설계 예정)
4. ~~암장 상세 / 섹터 / 문제 리스트~~ (완료 — Mock 기반)
5. 화면별 API 연동 (즐겨찾기/공지/스트릭/친구활동/암장상세/섹터/문제 API 등 `reports/` 요청사항 회신 대기)
6. 테스트/CI + 배포 설정

## 백엔드 연동 방식

백엔드 서버는 이 레포 밖 별도 위치에 이미 존재 (Spring Boot, 로컬 개발 중 `localhost:8080`). 화면 구현 중 특정 API가 필요해지는 시점에 사용자에게 개별 요청 → 제공받아 연동. 없는 API는 요청 후 구현되어 제공됨.

## 실행 방법

```bash
flutter pub get
flutter run -d chrome        # 또는 -d web-server --web-port <port>
flutter analyze
flutter test
```
