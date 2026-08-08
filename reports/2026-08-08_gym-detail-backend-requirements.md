# 백엔드 요청사항 보고서 — 암장 상세 / 섹터 / 문제

- **작성일**: 2026-08-08
- **작성자**: Claude (앱 개발)
- **배경**: 암장 상세 화면(배너, 난이도 체계, 섹터, 문제 리스트) 구현 중 확인된 필요 API

## 1. 신규 API 요청

### 1-1. 암장 상세 조회
- **용도**: `/gym/:id` 화면 전체 (이름, 로고, 사진 여러 장, 영업시간, 주소, 해시태그, 이용권, 난이도 체계)
- **요청 스펙(제안)**: `GET /api/gyms/{id}` →
  ```
  {
    id, name, logoUrl, photoUrls: [...], businessHours, address,
    hashtags: [...],
    gymType: "BOULDER" | "LEAD" | "BOTH",
    boulderDifficultySystem: [{label, colorHex}, ...],  // gymType이 BOULDER 또는 BOTH일 때만
    leadDifficultySystem: [{label, colorHex}, ...],      // gymType이 LEAD 또는 BOTH일 때만
    pricePlans: [{label, price}, ...]
  }
  ```
- **주의**:
  - `gymType`은 백엔드 `GymType` enum(BOULDER/LEAD/BOTH)과 동일하게 내려줘야 함. 클라이언트는 이 값으로 난이도 체계 표시 방식을 분기함(볼더=색 스트립, 리드=라벨 리스트, 둘 다=스와이프)
  - 난이도 체계는 암장마다 단계 수와 색이 다름 — 고정 enum이 아니라 암장별 커스텀 목록으로 설계 필요. BOULDER/LEAD 체계가 서로 다른 색상 집합을 가질 수 있음(BOTH 암장은 두 체계가 별도)
  - 사진은 여러 장(갤러리 스와이프) 필요 — 단일 `photoUrl`이 아니라 배열
- **현재 상태**: API 부재로 목업 데이터 3건(BOULDER 1, LEAD 0, BOTH 1 — 아직 순수 LEAD 암장 예시는 없음)으로 임시 구현함 ([gym_detail_mock_data.dart](../lib/features/gym/data/gym_detail_mock_data.dart))
- **우선순위**: 높음

### 1-1b. 길찾기
- **용도**: 상세 화면 주소 옆 "길찾기" 버튼 — 지도 앱으로 연결
- **필요 데이터**: 정확한 주소 또는 위경도 좌표 (`GET /api/gyms/{id}` 응답에 포함 권장)
- **현재 상태**: 버튼 UI만 있고 실제 지도 연동 없음 (탭하면 "준비 중" 안내만 표시). 좌표가 확정되면 `url_launcher` 패키지로 네이버/카카오/구글 지도 딥링크 연결 예정
- **우선순위**: 낮음

### 1-2. 섹터 / 문제 리스트
- **용도**: 암장 상세의 섹터 리스트, 섹터 탭 시 문제(루트) 리스트
- **요청 스펙(제안)**: `GET /api/gyms/{id}/sectors` → `[{id, name, description, discipline: "BOULDER" | "LEAD"}]`, `GET /api/gyms/{id}/sectors/{sectorId}/problems` → `[{id, grade, tapeColorHex, setter, setDate}]`
- **주의**: `BOTH` 암장은 섹터마다 볼더/리드가 섞여 있으므로 섹터 단위로 `discipline` 구분이 필요함 (문제 목록 화면에서 등급 표기 방식이 V-스케일 vs YDS로 달라짐)
- **현재 상태**: 암장별 섹터 2~3개, 문제 2~4개씩 목업으로 임시 구현함
- **우선순위**: 높음

### 1-3. 즐겨찾기 토글 / 알림 구독
- **용도**: 상세 화면 우측 상단 별표(즐겨찾기)·종(알림 구독) 버튼
- **요청 스펙(제안)**: `POST/DELETE /api/gyms/{id}/favorite`, `POST/DELETE /api/gyms/{id}/notification-subscription`
- **현재 상태**: 로컬 위젯 state로만 토글됨 — 새로고침하면 초기화되고, 홈 화면 즐겨찾기 목록과도 연동되지 않음
- **우선순위**: 중간 (홈 화면 즐겨찾기 API와 함께 설계하는 것을 권장 — 이전 보고서의 1-1 참고)
