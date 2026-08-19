# 백엔드 요청사항 보고서 — 문제 상세조회(루트 토포) 통계 API

- **작성일**: 2026-08-10
- **작성자**: Claude (앱 개발)
- **배경**: 일반 사용자용 문제 상세조회 화면([problem_detail_screen.dart](../lib/features/gym/presentation/problem_detail_screen.dart))을 "루트 토포" 형태(리드는 좌→우, 볼더는 하→상, 10개 단위 구간 + 낙하 지점 히트맵)로 구현. 화면 자체는 완성했지만 아래 통계 데이터는 현재 문제 API(`GET /api/problem/{id}`, `GET /api/problem/setting/{id}`)에 없어 문제 id를 시드로 한 목업([problem_try_mock_data.dart](../lib/features/gym/data/problem_try_mock_data.dart))으로 채워 넣은 상태입니다.
- **업데이트 (2026-08-10)**: "트라이 시작"/"여기서 떨어짐" 버튼을 실제로 동작하도록 만들었습니다 — 아래 2번 항목의 답이 "네, 별도 액션 필요"인 셈이라, 우선 [problem_try_providers.dart](../lib/features/gym/application/problem_try_providers.dart)의 `StateNotifierProvider`로 로컬 상태에만 기록을 쌓는 방식으로 구현해뒀습니다(트라이 기록 리스트 UI 포함). 세션 동안만 유지되고 앱을 새로 켜면 초기화됩니다 — 아래 API가 생기면 이 로컬 상태를 실제 저장/조회로 교체할 예정입니다.
- **업데이트 2 (2026-08-10) — 낙하 메모 + 점장님의 팁**: "여기서 떨어짐"을 누르면 확인 모달이 뜨도록 바꿨습니다. 모달에는 (1) "어떤 홀드였나요?" 메모 입력(선택, 트라이 기록에 함께 저장)과 (2) 그 홀드에 등록된 **"점장님의 팁"**(홀드별 공략 조언, 현재는 홀드 순번 기준 목업)을 함께 보여줍니다. **신규 요청사항**: "점장님의 팁"은 사용자에게는 조회 전용이고 실제로는 GYM_MANAGER가 문제(또는 홀드 단위)에 팁을 작성/수정하는 기능이 필요합니다 — (1) 팁이 홀드 단위로 붙는지 문제(루트) 전체 단위로 붙는지, (2) 매니저용 문제관리 화면에 팁 작성 CRUD를 추가해야 하는지 확인 부탁드립니다.
  - **업데이트 (2026-08-19) — 일단 숨김 처리**: 매니저가 팁을 작성하는 기능이 없어 목업만 계속 보여주는 상태였는데, 사용자 확인 하에 "점장님의 팁" UI 자체를 숨김 처리했습니다(`_ManagerTipCard`, `mockManagerTips` 제거). 위 CRUD 관련 API가 확정되면 다시 추가하겠습니다 — 이 요청사항은 계속 열어둡니다.
- **업데이트 3 (2026-08-10) — `GET /api/problem/{id}/detail` + `problemTryLog` CRUD 연동**: 주신 API로 연동했습니다.
  - `GET /api/problem/{id}/detail`의 `holdCount`, `clearCount`, `myBestDropPoint`를 그대로 씁니다 — 홀드 갯수/클리어 인원/"내 최고 도달" 통계가 이제 실데이터입니다. [gym_problem_detail.dart](../lib/features/gym/domain/gym_problem_detail.dart)
  - "여기서 떨어짐" 확인 모달에서 "기록하기"를 누르면 실제로 `POST /api/problemTryLog`를 호출합니다(`problemId`/`dropPoint`/`memo`/`tryDate`). 성공하면 문제 상세를 다시 불러와 서버가 재계산한 `myBestDropPoint`를 반영합니다. `userId`는 로그인한 사용자 기준으로 서버가 정하는 것으로 보고 요청 본문에 넣지 않았습니다 — 맞는지 확인 부탁드립니다.
  - **막힌 부분 — "트라이 기록" 리스트를 과거 기록까지 보여줄 수 없습니다**: 주신 조회 API는 `GET /api/problemTryLog/user/{userId}`(사용자 전체, 문제 무관, 페이지네이션)뿐이라, 특정 문제의 내 기록만 뽑아 보여주려면 (a) 로그인 사용자의 숫자 `userId`를 클라이언트가 알아야 하는데 현재 로그인 응답(`{token, username, role, nickname, managedGymId}`)에 숫자 id가 없고, (b) 있다 하더라도 이 API가 전체 문제를 섞어 최신순으로 주기 때문에 이 문제만 필터링하려면 사용자의 모든 트라이 기록을 다 훑어야 합니다. 그래서 지금은 "트라이 기록" 섹션에 **이번 세션에 새로 기록한 것만** 보여주고 있습니다(화면에 안내 문구 추가함). 아래 둘 중 하나를 부탁드립니다 — (1) 로그인 응답 또는 `/api/auth/me` 같은 API에 숫자 `userId`를 포함해주시거나, (2) `GET /api/problemTryLog/problem/{problemId}`처럼 로그인 사용자 + 특정 문제로 바로 필터링되는 조회 API를 추가해주시면(둘 중 하나만 있어도 충분) 과거 기록까지 보여주도록 연동하겠습니다.
- **업데이트 4 (2026-08-10) — 회신 반영**:
  - `tryDate`는 클라이언트가 뭘 보내도 서버가 항상 오늘 날짜로 저장한다고 확인해주셔서, `createTryLog`/`updateTryLog` 요청 본문에서 아예 빼도록 수정했습니다.
  - `GET /api/problem/{id}/detail`의 트라이 집계 필드가 `tryCount` → **`myTryCount`**로 이름이 바뀌었고(로그인 사용자 개인 기준, `countByUserAndProblem(user, problem)`), 확인해주신 대로 [gym_problem_detail.dart](../lib/features/gym/domain/gym_problem_detail.dart)에 반영해 "내 트라이" 통계 카드로 화면에 노출했습니다(홀드 갯수/내 트라이/내 최고 도달/클리어 인원 4개 카드).
  - **비로그인 게스트는 401이 아니라 403** — `GET /api/problem/{id}/detail`을 게스트가 호출하면 403이 내려온다고 확인해주셨습니다. 그래서 이 화면은 게스트에게 "체험 모드"를 보여주도록 만들었습니다: `gymProblemDetailProvider`가 403을 받으면 공개 API인 `GET /api/problem/{id}`(인증 불필요, `clearUserCount` 등 포함)로 대체 조회하고, 서버가 못 주는 `holdCount`만 문제 id 기준 목업으로 채웁니다([gym_providers.dart](../lib/features/gym/application/gym_providers.dart)의 `gymProblemDetailProvider`). 화면 상단에 "게스트 체험 모드" 안내 배너를 띄우고, 이 상태에서 "트라이 시작"/"여기서 떨어짐"을 눌러도 `POST /api/problemTryLog`를 호출하지 않고 세션 로컬에만 기록을 남깁니다(화면을 나가면 사라짐 — `ProblemTryLog.isLocalOnly`).
  - **재확인 부탁드리는 것**: (1) 게스트 403이 의도된 정책이 맞는지(즉 이 화면은 항상 로그인 사용자만 실제 서버 기록을 볼 수 있는 설계가 맞는지), (2) `createTryLog`도 게스트가 호출하면 마찬가지로 403인지(현재는 게스트일 때 아예 호출을 안 하도록 클라이언트에서 막아뒀습니다), (3) 위 "트라이 기록" 과거 조회 문제(userId 노출 또는 문제별 조회 API)는 여전히 열려있습니다.
- **업데이트 5 (2026-08-10) — "확인 필요한 것" 1~3번 회신**: 아래 정리한 대로, 저희가 만든 구조(홀드는 서버 개념이 아니라 `holdCount` 기준 순번, "여기서 떨어짐" = `POST /api/problemTryLog`, 낙하 지점 = `dropPoint`)가 그대로 맞는 방향이라고 확인해주셨습니다 — 코드 변경 없이 문서만 정리합니다.
  1. **"홀드" 단위는 서버에 없음** — `Problem.holdCount`로 마지막 홀드 번호만 정하고, 그 안에서 "몇 번째 홀드에서 떨어짐"으로만 표현합니다. 지금 구현(좌표·형태 없이 1~holdCount 사이의 순번만 다루는 것)이 정확히 이 모델과 일치합니다.
  2. **"여기서 떨어짐" = `POST /api/problemTryLog`로 시도 기록 생성** — 이미 이렇게 연동돼 있습니다(업데이트 3/4).
  3. **낙하 지점은 `ProblemTryLog.dropPoint`로 모을 예정** — 커뮤니티 낙하 지점 히트맵(루트 토포에서 홀드 색 진하기로 보여주는 부분)이 여기서 나올 데이터라는 뜻으로 이해했습니다.
- **업데이트 6 (2026-08-10) — `GET /api/problem/{id}/dropPointStats` 연동 완료**: 요청드린 집계 API가 나와서 바로 연동했습니다. `distribution`(홀드 순번 → 인원수)을 루트 토포 히트맵에 그대로 씁니다 — 로그인 사용자는 이제 낙하 지점 분포도 실데이터입니다([gym_api.dart](../lib/features/gym/data/gym_api.dart)의 `fetchDropPointStats`, [gym_providers.dart](../lib/features/gym/application/gym_providers.dart)의 `dropPointStatsProvider`). **게스트 체험 모드는 여전히 목업**을 씁니다 — 체험 모드의 `holdCount` 자체가 목업이라 실제 `distribution`의 `dropPoint` 값과 안 맞을 수 있어서, 게스트에게는 일관성을 위해 계속 목업 히트맵을 보여줍니다. 이제 이 화면에 남은 목업은 "점장님의 팁"과 게스트 체험 모드 전용 데이터뿐입니다.
- **업데이트 7 (2026-08-10) — `clearRecord` API 연동 (부분)**: 주신 완등 기록(ClearRecord) API 중, 사용자 확인을 거쳐 아래 범위로 연동했습니다.
  - "트라이 시작"을 누르면 이 화면에 머무는 동안 **한 번만** `POST /api/clearRecord`(진행 중, `isClear=false`/`startDate=오늘`)를 만들고, 완등 전까지 재사용합니다(같은 화면에서 "트라이 시작"을 여러 번 눌러도 기존 진행 중 기록을 계속 씁니다). 완등(마지막 홀드에서 "완등으로 기록")하면 `PATCH /api/clearRecord/{id}/clear`로 완등 처리합니다. [problem_try_providers.dart](../lib/features/gym/application/problem_try_providers.dart)
  - ~~**알려진 한계**: user+problem 기준으로 "이미 진행 중인 ClearRecord가 있는지" 조회하는 API가 없어서...~~ → **업데이트 8에서 해결(API는 받았으나 다른 이유로 아직 연동 보류)**.
- **업데이트 8 (2026-08-10) — `GET /api/clearRecord/user/{userId}/problem/{problemId}/inProgress` 받음, 연동은 보류**: 위에서 요청드린 진행 중 기록 조회 API를 주셨습니다 — `fetchInProgressClearRecord`로 [gym_api.dart](../lib/features/gym/data/gym_api.dart)에 메서드는 추가해뒀지만, **아직 `ProblemTryNotifier`에 실제로 연결하지 않았습니다**. 이유: 이 API도 경로에 로그인 사용자의 숫자 `userId`가 필요한데, 클라이언트는 여전히 그 값을 모릅니다(업데이트 3에서부터 계속 열려있던 문제 — 로그인 응답에 숫자 id가 없음). 이 상태로 무리하게 연동하면 잘못된 값을 넣거나 기능이 반쪽으로 남을 것 같아, 말씀하신 대로 **구현을 멈추고 먼저 요청드립니다**.
  - **필요한 것 (택1)**: (1) 로그인 응답(`POST /api/auth/login`)에 숫자 `userId`(또는 `id`) 필드를 추가해주시거나, (2) `GET /api/auth/me`처럼 토큰만으로 현재 로그인 사용자 정보(숫자 id 포함)를 조회하는 API를 추가해주세요. 이 값이 생기면 아래 세 가지를 한 번에 연동할 수 있습니다 — (a) 이번 `inProgress` 조회로 "트라이 시작" 시 기존 진행 중 기록 재사용, (b) `GET /api/problemTryLog/user/{userId}`로 문제 상세의 "트라이 기록" 과거 이력 표시, (c) `GET /api/clearRecord/user/{userId}` 계열(완등 기록/랭킹 탭에서 쓸 것으로 예상).
- **업데이트 9 (2026-08-10) — 로그인 응답에 `userId` 추가 완료, (a)/(b) 연동 완료**: 로그인 응답에 `userId`가 추가됐다고 확인해주셔서 바로 반영했습니다.
  - `CurrentUser.userId`([current_user.dart](../lib/features/auth/domain/current_user.dart))로 저장 — 기존에 저장돼 있던 세션(이 변경 전 로그인)은 이 필드가 없어 `null`로 복원되고, 재로그인해야 채워집니다(안전하게 nullable로 처리해 기존 세션 복원이 깨지지 않도록 함).
  - **(a) 진행 중 완등 기록 재사용**: `ProblemTryNotifier.startTry()`가 이제 `userId`가 있으면 `GET /api/clearRecord/user/{userId}/problem/{problemId}/inProgress`로 먼저 조회하고, 있으면 그 기록을 재사용, 없으면 새로 생성합니다.
  - **(b) "트라이 기록" 과거 이력 표시**: `myProblemTryLogsProvider`([gym_providers.dart](../lib/features/gym/application/gym_providers.dart))가 `GET /api/problemTryLog/user/{userId}`(최근 100건)를 조회해 `problemId`로 걸러 보여줍니다. `userId`를 아는 로그인 사용자는 이제 "이번 세션에 새로 기록한 것만" 문구 없이 실제 과거 기록이 보이고, 새 트라이를 기록하면 자동으로 갱신됩니다. userId를 모르는(구 세션) 경우엔 "다시 로그인하면 과거 기록도 볼 수 있어요" 안내로 대체.
  - **(c) `GET /api/clearRecord/user/{userId}` 계열**은 아직 미착수입니다 — 완등 기록/랭킹(`RecordScreen`) 쪽 새 화면 작업이 될 것 같아 별도로 진행 여부를 여쭤보겠습니다.
  - **이번 범위에서 제외한 것(사용자 확인)**: 완등 인증 영상(`videoUrl`) 입력, 다른 사람 완등 영상 갤러리(`GET /api/clearRecord/existVideo/...`) — 둘 다 후속 작업으로 미룸.
  - **아직 안 쓰는 나머지 API**: `PUT /api/clearRecord/{id}`, `DELETE /api/clearRecord/{id}`, `GET /api/clearRecord/user/{userId}`(+`/setting/{settingId}`, `/gym/{gymId}`), `GET /api/clearRecord/stats/user/{userId}/gym/{gymId}` — 사용자별 조회·통계는 기존에 막힌 숫자 `userId` 문제와 동일하게 걸려있어서, 그 문제가 풀리면 "완등 기록/랭킹" 탭 쪽에서 활용할 수 있을 것 같습니다.
- **업데이트 10 (2026-08-18) — 통계 카드에 트라이 시작일자/완등일자 추가, 완등일자는 알려진 한계 있음**: 홀드 갯수·내 트라이·내 최고 도달·클리어 인원 카드에 이어 "트라이 시작일자"/"완등일자"를 추가했습니다.
  - **시작일자**: `GET /api/clearRecord/user/{userId}/problem/{problemId}/inProgress`로 진행 중인 완등 기록을 조회해 `startDate`를 보여줍니다. 없으면(트라이한 적이 없으면) "미시작" — 이 부분은 100% 정확합니다.
  - ~~**완등일자 — 한계 있음**: ... 정확하게 고치려면 ... API가 필요합니다.~~ → **업데이트 11에서 다른 방식으로 해결(신규 API 불필요)**.
- **업데이트 11 (2026-08-18) — 시작일자/완등일자를 `problemTryLog`에서 구하는 방식으로 교체**: `GET /api/problemTryLog/user/{userId}`(이미 "트라이 기록" 리스트에 쓰던 것과 같은 API, `myProblemTryLogsProvider`)로 바꿔서 풀었습니다 — 제안 감사합니다. `ClearRecord` 조회 API보다 오히려 나은 점이 있어서 이쪽으로 완전히 교체했습니다.
  - **시작일자** = 문제별 트라이 기록 중 가장 오래된 `tryDate`. **완등일자** = `dropPoint >= holdCount`인 기록 중 가장 최근 `tryDate`. 둘 다 없으면 "미시작"/"미완등".
  - **`ClearRecord`의 `inProgress` 조회보다 나은 점**: (1) `problemTryLog`는 `problemId`가 정확해 헷갈릴 일이 없고(완등 기록 리스트 API의 `problemName` 문자열 매칭 문제가 없음), (2) 과거 세션에 완등한 기록도 (최근 100건 안에 있으면) 잡혀서 "이번 세션에 완등한 것만 보임"이라는 한계가 사라졌습니다.
  - **남은 한계**: `myProblemTryLogsProvider`가 최신 100건만 조회하기 때문에, 트라이가 아주 많은 사용자는 오래된 시작일자/완등일자를 놓칠 수 있습니다(기존에 "트라이 기록" 리스트에도 있던 것과 동일한 한계).
  - 이제 화면에서 `ClearRecord`는 "트라이 시작 시 기존 진행 중 기록 재사용 + 완등 처리"용으로만 쓰고, 날짜 표시에는 관여하지 않습니다. 이전에 요청드렸던 "완등 여부 무관 최신 기록 조회 API"는 더 이상 필요 없어졌습니다.

## 필요한 데이터

- **홀드 갯수**: 문제(루트)를 구성하는 전체 홀드 수
- **내 진행 정보**: 로그인한 사용자가 이 문제에서 도달한 최고 지점(홀드 순번 등으로 표현 가능)
- **내가 트라이를 시작한 일자**: 이 문제를 처음 시도한 날짜
- **내가 트라이한 횟수**: 이 문제에 대한 내 시도 총 횟수
- **내가 어디서 떨어졌는지**: 가장 최근 시도에서 떨어진 지점
- **사람들이 떨어진 곳들에 대한 정보**: 다른 사용자들이 각 홀드(구간)에서 떨어진 횟수/분포 — 화면에서 홀드 색상 히트맵으로 표시하는 데 사용
- 클리어 인원은 기존 `GET /api/problem/setting/{id}` 응답의 `clearUserCount`를 그대로 재사용 중이라 추가 요청 없음.

## 확인 필요한 것

1. ~~"홀드"라는 단위가 서버 데이터 모델에도 존재하는지~~ — ✅ 답변 완료(업데이트 5): 없음, `holdCount` 기준 순번만 사용.
2. ~~"내 진행/트라이 기록"은 사용자별 시도 기록을 별도로 남기는 액션이 필요한 기능인지~~ — ✅ 답변 완료(업데이트 5): `POST /api/problemTryLog`.
3. ~~"낙하 지점" 데이터를 홀드 단위로 모을지~~ — ✅ 답변 완료(업데이트 5): `ProblemTryLog.dropPoint`로 수집 예정. 집계 조회 API는 아직 없어 업데이트 5에 후속 요청 남김.

> 볼더 문제 상세도 현재는 동일한 필드(홀드 갯수/진행/트라이/낙하 지점/클리어 인원)로 구성해뒀습니다 — 볼더 전용 스펙이 정해지면 알려주세요.
