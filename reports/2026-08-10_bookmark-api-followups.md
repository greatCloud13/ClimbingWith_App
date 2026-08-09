# 백엔드 요청사항 보고서 — 즐겨찾기(북마크) API 연동 후속

- **작성일**: 2026-08-10
- **작성자**: Claude (앱 개발)
- **배경**: 암장 상세 별 버튼에 `POST /api/bookmark/{gymId}` / `DELETE /api/bookmark/{id}` 연동 완료. 연동 중 확인된 구조적 한계 하나를 보고.

## 1. 북마크 해제(DELETE)에 필요한 id — ✅ 완전히 해결 (2026-08-10)

- 처음엔 별도 `bookmarkIdList`를 `gymCardList`와 같은 순서로 대응시켰는데, 1:1로 안 맞는다는 걸 확인해주셔서 `gymCardList[].bookmarkId` 명시적 필드로 교체 반영했습니다 — 이제 위치 추정 없이 안전하게 매칭됩니다.
- 이번 세션에 앱에서 직접 등록한 북마크는 여전히 `bookmarkIdMapProvider`로 별도 추적하고, `GET /api/home`의 `bookmarkId`는 그 다음 fallback으로 사용합니다.
