# 백엔드 요청사항 보고서 — 운동기록 탭 "최근 완등 기록" API

- **작성일**: 2026-08-19
- **작성자**: Claude (앱 개발)
- **배경**: 운동기록(`/record`) 탭에서 이번달 완등/최고 난이도/연속 방문 통계와 이번주 랭킹은 사용자 확인 하에 숨김 처리했고([record_screen.dart](../lib/features/record/record_screen.dart)), "최근 완등 기록" 리스트만 남았습니다. 지금은 목업(`_recentClimbs`)이라 이걸 실제 API로 교체하려 합니다.

## 쓰려고 하는 API

이미 명세를 받은 아래 API를 그대로 쓸 계획입니다 — 새 API를 만들어달라는 요청이 아니라, 기존 API로 진행해도 괜찮을지 + 화면 구성에 부족한 부분만 확인 요청드립니다.

```
GET /api/clearRecord/user/{userId}?page=0&size=10&sort=clearDate,desc
```

응답(`content[]` 항목): `{clearRecordId, username, problemName, level, gymName, sectorName, clearDate}`

`userId`는 로그인 응답에 이미 포함되어 있어(`CurrentUser.userId`) 바로 쓸 수 있습니다. "최근"이라는 화면 성격에 맞게 `size`를 작게(예: 10) 잡아 최신 완등 기록만 가져올 예정입니다.

## 확인/추가 요청 사항

1. ~~**`problemId`(및 이동에 필요한 id들) 누락**~~ → ✅ 완전 해결(업데이트 2): `problemId` 추가됨.
2. ~~**시도 횟수(attempts) 표시 여부**~~ → ✅ 해결(업데이트 1): `tryCount` 필드로 추가됨.
3. **페이지네이션**: "최신 일자순 정렬"은 이미 확인했습니다. 지금은 최근 N건만 보여줄 예정인데, 나중에 "더보기" 버튼으로 다음 페이지를 불러오는 것도 이 API 그대로 가능한 게 맞을까요? (아직 미확인)
4. **gymName/sectorName 스냅샷 여부**: 완등 시점의 이름 스냅샷인지, 현재 값인지 궁금합니다 — 급한 건 아니고 참고용입니다. (아직 미확인)

- **업데이트 1 (2026-08-19) — 응답 확장, `problemId`만 남음**: `gymId`/`sectorId`/`settingId`/`tryCount`/`levelColorCode`가 추가된 새 응답을 확인했습니다. **`problemId`만 빠져 있어서, 카드를 탭했을 때 문제 상세 화면으로 정확히 이동시킬 방법이 아직 없습니다.** `problemName` 매칭은 이름이 겹칠 수 있어 쓰지 않기로 했습니다(이전에 말씀드린 것과 동일한 이유). 확인 결과 **`problemId`가 추가될 때까지 개발을 대기하기로 했습니다** — 응답에 `problemId`가 추가되면 바로 화면 연동을 진행하겠습니다.
- **업데이트 2 (2026-08-19) — `problemId` 추가 확인, 연동 완료**: `problemId`가 응답에 추가된 것을 확인하고 바로 연동했습니다. [record_api.dart](../lib/features/record/data/record_api.dart)의 `fetchRecentClearRecords(userId, size: 10)`로 "최근 완등 기록" 카드를 채우고, 탭하면 `problemId`/`gymId`/`sectorId`로 문제 상세 화면까지 정확히 이동합니다. `level`/`levelColorCode`는 V등급이 아니라 암장별 커스텀 레벨이라, 다른 화면들과 통일감 있게 색 스와치+이름으로 표시했습니다(`GradeBadge` 대신). 3번(페이지네이션 재사용 가능 여부)·4번(gymName/sectorName 스냅샷 여부)은 급하지 않아 미확인 상태로 남겨둡니다 — 필요해지면 다시 여쭤보겠습니다.
