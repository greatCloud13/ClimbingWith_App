# 백엔드 요청사항 보고서 — 섹터 관리 API 연동 후속

- **작성일**: 2026-08-10
- **작성자**: Claude (앱 개발)
- **배경**: 문제관리(GYM_MANAGER) depth는 섹터 → 세팅 → 문제 순서로 진행 중. 1단계인 섹터 관리(목록/생성/수정) 화면을 구현하면서 확인된 사항.

## 1. 섹터 생성/수정 — ✅ 연동 완료 (2026-08-10)

- `POST /api/sector`(생성), `PUT /api/sector/{sectorId}`(수정) 연동 완료. [gym_api.dart](../lib/features/gym/data/gym_api.dart)의 `createSector`/`updateSector`, 화면은 [gym_manage_screen.dart](../lib/features/gym_manage/gym_manage_screen.dart)(목록) / [sector_form_screen.dart](../lib/features/gym_manage/presentation/sector_form_screen.dart)(폼).
- 응답이 `{success, data, error}`로 감싸져 있어 `data`만 꺼내 쓰도록 처리했습니다.
- 섹터 목록은 별도 리스트 API 없이 기존 `GET /api/gym/{id}`의 `sectorList` 필드를 재사용했습니다(관리 중인 암장 = `managedGymId`) — `POST`/`PUT` 응답의 `data` 필드명과 `sectorList` 항목 필드명이 동일해서 같은 파서(`Sector.fromApiJson`)로 처리 가능했습니다.

## 2. 섹터 삭제/비활성화 API — 대기 중

- 말씀하신 대로 아직 없다는 것 확인했고, 두 API를 인지한 상태로 화면 구조를 잡아뒀습니다(목록 화면에 삭제/비활성화 액션은 아직 추가 안 함 — API 확정되면 바로 붙일 수 있는 구조).
- 확정해서 알려주시면 좋은 것: (1) 삭제는 하드 삭제인지, 비활성화와 별개로 존재하는 이유(둘 다 있으면 차이가 뭔지), (2) 비활성화된 섹터가 `GET /api/gym/{id}`의 `sectorList`에 계속 포함되는지(포함 여부를 나타내는 필드가 있는지) — 목록 화면에서 비활성 섹터를 다르게 표시해야 할 수 있어서요.

## 3. 세팅 기록 화면 — ✅ 연동 완료 (2026-08-10)

- `GET /api/sector/{id}`로 섹터를 탭하면 세팅 기록(`settingList`: 시작일/종료일/진행중 여부)을 보여주는 화면을 만들었습니다. [sector_settings_screen.dart](../lib/features/gym_manage/presentation/sector_settings_screen.dart)

## 4. 세팅 CRUD — ✅ 연동 완료 (2026-08-10)

- `POST /api/setting`(생성, sectorId+gymId만), `PUT /api/setting/{id}`(기간 수정), `DELETE /api/setting/{id}`(삭제) 연동 완료. [gym_api.dart](../lib/features/gym/data/gym_api.dart)의 `createSetting`/`updateSetting`/`deleteSetting`, 화면은 [setting_form_screen.dart](../lib/features/gym_manage/presentation/setting_form_screen.dart).
- 생성이 기간 정보를 안 받는다고 하셔서, "새 세팅 시작" 버튼 → 생성 API 호출 → 곧바로 수정 폼(세팅일/시작일/종료일)으로 자동 이동하는 흐름으로 만들었습니다.
- `endDate`는 nullable이라고 확인해주셔서, `PUT` 요청 시 값이 없으면(진행 중 세팅) 필드 자체를 생략하는 지금 방식 그대로 유지합니다.
- `GET /api/setting/{id}`(문제 목록 `problemList` 포함)와 `GET /api/setting/gym/{id}`(암장 전체의 활성 세팅 목록)는 이번 범위에서 아직 안 썼습니다 — 필요해지면 쓰겠습니다.

## 5. 문제(루트) CRUD — ✅ 연동 완료 (2026-08-10)

- `GET /api/problem/setting/{id}`(목록), `POST /api/problem`(등록), `PUT /api/problem/{id}`(수정), `DELETE /api/problem/{id}`(삭제) 모두 연동 완료. 세팅 카드를 탭하면 문제 목록([problem_list_screen.dart](../lib/features/gym_manage/presentation/problem_list_screen.dart)) → "새 문제"/문제 탭 시 등록·수정 폼([problem_form_screen.dart](../lib/features/gym_manage/presentation/problem_form_screen.dart)).
- **수정 시 난이도 프리필 관련 참고**: `GET /api/problem/setting/{id}` 응답에 `gymLevel`(이름 문자열)만 있고 `gymLevelId`가 없어서, 수정 폼에서는 이름이 같은 난이도를 목록에서 찾아 자동 선택하는 방식으로 처리했습니다. 혹시 이름이 중복되거나 목록에서 사라진 난이도라면 자동 선택이 안 되어 사용자가 직접 다시 골라야 합니다 — `GET /api/problem/{id}` 응답에 `gymLevelId`가 추가되면 더 정확해질 것 같습니다(선택 사항입니다).

## 6. 난이도(레벨) CRUD — ✅ 연동 완료 (2026-08-10)

- `GET /api/level/gym/{gymId}`(목록), `POST /api/level`(생성), `PUT /api/level/{id}`(수정), `DELETE /api/level/{id}`(삭제) 모두 연동 완료.
- 문제 등록/수정 폼에서 선택한 종목(볼더/리드)에 해당하는 난이도가 하나도 없으면, 드롭다운 대신 "난이도 등록하기" 버튼이 나와서 그 자리에서 바로 만들고 이어서 문제를 등록할 수 있습니다.
- **문제관리 탭에 "난이도" 탭을 추가했습니다(2026-08-10)**: [gym_manage_screen.dart](../lib/features/gym_manage/gym_manage_screen.dart) 상단이 "섹터"/"난이도" 두 탭으로 나뉘고, 난이도 탭에서는 종목(볼더/리드/미지정)별로 묶어 색 스와치 + 이름 + 설명을 보여주며 생성/수정/삭제가 가능합니다([level_form_screen.dart](../lib/features/gym_manage/presentation/level_form_screen.dart)). 삭제는 해당 난이도를 쓰는 문제가 있으면 실패할 수 있어 안내 문구로 대응했습니다(세팅 삭제 때와 같은 패턴).

## 7. 세팅 활성화/비활성화 — ✅ 연동 완료 (2026-08-10)

- `PATCH /api/setting/{id}/disable`, `PATCH /api/setting/{id}/active` 연동 완료. 세팅 카드에 일시정지/재생 아이콘 버튼으로 추가했습니다([sector_settings_screen.dart](../lib/features/gym_manage/presentation/sector_settings_screen.dart)).
- 세팅 삭제(`DELETE /api/setting/{id}`)가 실패하면(등록된 문제가 있어서 등) 안내하신 대로 "등록된 문제가 있다면 문제를 먼저 삭제해주세요"라는 안내 문구를 보여주도록 했습니다 — 서버가 내려주는 원본 에러 메시지 대신 항상 이 문구로 고정했습니다(에러 응답이 DB 제약조건 예외처럼 사용자에게 그대로 보여주기 부적절한 경우가 많을 것 같아서요). 혹시 이 실패가 "문제가 남아있어서"가 아닌 다른 이유(권한 등)로도 발생할 수 있다면 알려주세요 — 메시지를 상황별로 나눠야 할 수도 있습니다.

## 8. 문제 목록 — 난이도 색상 표시 + 필터링 — ✅ 연동 완료 (2026-08-10)

- 문제 응답에 추가해주신 `colorCode`(색상 코드)와 `levelId`를 반영했습니다. [gym_problem.dart](../lib/features/gym/domain/gym_problem.dart)의 `GymProblem.colorCode`/`levelId`(둘 다 nullable로 처리 — 필드가 없는 응답이 와도 안전하게 동작).
- 문제 목록 각 항목의 난이도 표시를 텍스트 배지에서 **색상 원(스와치) + 이름**으로 바꿨습니다(기존 공개 화면의 테이프색 원과 같은 스타일). `colorCode`가 없는 항목은 회색 원으로 대체 표시합니다. 문제 등록/수정 폼의 난이도 드롭다운에도 같은 색 스와치를 추가했습니다.
- 문제 목록 상단에 난이도별 필터 칩을 추가했습니다 — 해당 세팅에 실제로 존재하는 난이도만 칩으로 보여줍니다(전체 암장 난이도가 아니라 이 화면에 뜬 문제들 기준).
- `levelId`가 응답에 포함된 덕분에, 수정 폼의 난이도 자동 선택도 이름 매칭 대신 id로 바로 처리하도록 개선했습니다 — 이전에 남겼던 "이름 중복 시 자동 선택 실패" 우려가 해소됐습니다.

이제 섹터 → 세팅 → 문제 depth가 전부 CRUD 연동 완료입니다(세팅 활성/비활성, 난이도 색상 표시·필터링 포함). 남은 건 섹터 자체의 삭제/비활성화 API뿐입니다(2번 항목, 아직 미확정).

> 섹터 삭제/비활성화 API 스펙 확정되면 알려주세요.
