# 백엔드 요청사항 보고서 — GYM_MANAGER 홈(캘린더/게시판 CRUD) · 문제관리 탭

- **작성일**: 2026-08-10
- **작성자**: Claude (앱 개발)
- **배경**: GYM_MANAGER 역할 전용 화면 개발 시작. 로그인 후 홈 화면 메인에 캘린더 + 게시판 CRUD, 하단탭 4번째("문제관리")에 문제(루트) CRUD를 배치할 예정. 현재 앱에는 조회(GET)만 연동되어 있고 아래 항목은 API가 없어 화면 구현이 막혀 있음.

## 1. 게시판 글 작성/수정/삭제 API — ✅ 연동 완료 (2026-08-10)

- 제공해주신 스펙대로 연동 완료: `GET /api/post/{postId}`(상세), `POST /api/post`(작성), `PUT /api/post/{postId}`(수정), `DELETE /api/post/{postId}`(삭제). [gym_api.dart](../lib/features/gym/data/gym_api.dart), 화면은 [gym_manager_board_screen.dart](../lib/features/gym_manage/presentation/gym_manager_board_screen.dart) / [gym_post_form_screen.dart](../lib/features/gym_manage/presentation/gym_post_form_screen.dart).
- `POST /api/post`가 경로에 gymId 없이 인증된 사용자의 관리 암장으로 자동 매핑된다고 이해하고 그렇게 구현했습니다 — 서버가 실제로 `managedGymId` 기준 권한 체크를 하고 있는지만 확인 부탁드립니다(다른 매니저의 글을 postId로 수정/삭제 요청했을 때 403이 오는지).
- `/api/post/search`는 이번 범위에서는 사용하지 않았습니다. 필요해지면 별도 요청드리겠습니다.

## 2. 문제(클라이밍 루트) CRUD API

- 현재 연동: 없음. [climbing_problem.dart](../lib/features/gym/domain/climbing_problem.dart)는 도메인 모델만 있고, [sector_problems_screen.dart](../lib/features/gym/presentation/sector_problems_screen.dart)는 목업 데이터만 표시 중.
- 필요: 섹터별 문제 등록(`POST`), 수정(`PUT`), 삭제/철거 처리(`DELETE` 또는 상태값), 문제 목록 조회(`GET`, 관리자용 — 철거된 문제 포함 여부 등)
- 문제 필드는 기존 `ClimbingProblem` 모델(등급, 테이프 색, 셋터, 셋팅일) 기준으로 맞춰주시면 됩니다. 필드가 추가/변경되면 알려주세요.

## 3. 캘린더/일정 데이터 API

- 현재 연동: 없음.
- 필요: GYM_MANAGER가 관리하는 암장의 일정(예: 셋팅일, 이벤트일 등) 목록을 월 단위로 조회하는 API. 일정 등록/수정/삭제가 필요한지, 아니면 문제 셋팅일 등 기존 데이터에서 자동 집계되는 것인지 방향을 정해주시면 그에 맞춰 요청드리겠습니다.

> 우선순위나 필드 스펙에 대한 의견 있으시면 알려주세요. API가 확정되는 대로 화면 연동 진행하겠습니다.
