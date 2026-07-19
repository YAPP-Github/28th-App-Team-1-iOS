# Color — HILIT 색 토큰

단일 소스: `Shared/SharedDesignSystem/Interface/Colors/Color+DS.swift` + `Interface/Resources/Colors.xcassets`. Figma 색 변수와 1:1, 라이트 단일 값(다크모드 제한).

**주의 — gray 컬렉션 2벌**: Figma 에 신형 `grayscale/gray-N` 과 구형 `Gray scale/N` 이 공존한다(팔레트 마이그레이션 중으로 보임). 신형 → `dsGrayN`, 구형 → `dsGrayScaleN` 으로 분리했고, 디자인이 한 벌로 정리되면 Color+DS.swift 에서 일괄 치환한다. dsGray500/dsGray800 은 구형 소속이지만 선점된 평탄 이름을 유지 중.

| 토큰 | Figma 변수 | hex | 용도 |
|---|---|---|---|
| `Color.dsBlack` | hilit black | #1A1B1F | CTA·뱃지 바탕, 강조 보더, 진행 바 활성 |
| `Color.dsWhite` | hilit white | #FFFFFF | 화면·칩 바탕 |
| `Color.dsGreen500` | hilit green/500 | #ACEBA0 | 브랜드 그린 포인트, 진행 스트립 |
| `Color.dsGreen800` | hilit green/800 | #106100 | 성공 메시지 텍스트 |
| `Color.dsGray50` | grayscale/gray-50 | #F6F7F9 | 옅은 면 (진행 바 비활성, 뱃지 바탕) — Figma 값 갱신으로 #F0F1F3→#F6F7F9 |
| `Color.dsGray100` | grayscale/gray-100 | #E0E1E7 | 필드 보더, placeholder |
| `Color.dsGray200` | grayscale/gray-200 | #BCBEC6 | 비활성 탭 텍스트 |
| `Color.dsGray300` | grayscale/gray-300 | #9DA0AC | 헬퍼(idle) 텍스트 |
| `Color.dsGray400` | grayscale/gray-400 | #8A8D9C | 비활성 텍스트 |
| `Color.dsGray500` | Gray scale/500 | #8990A0 | 보조 텍스트 |
| `Color.dsGray600` | grayscale/gray-600 | #636777 | 로딩 중 본문 텍스트 |
| `Color.dsGray700` | grayscale/gray-700 | #494C58 | CTA 구분선, 스피너 트랙, 카운터 |
| `Color.dsGray800` | Gray scale/800 | #262A30 | 강조 본문, PDF 뱃지 바탕 |
| `Color.dsGray900` | grayscale/gray-900 | #27282F | 진한 보조 텍스트 |
| `Color.dsGrayScale100` | Gray scale/100 | #F3F4F6 | 진행 스트립 트랙, 업로드 카드 바탕 |
| `Color.dsGrayScale200` | Gray scale/200 | #E3E6EC | 입력창·카드 보더 |
| `Color.dsGrayScale400` | Gray scale/400 | #B6BCC8 | 완료 서브 텍스트, 아이콘 틴트 |
| `Color.dsGrayScale600` | Gray scale/600 | #6D7382 | 카드 캡션 |
| `Color.dsGrayScale700` | Gray scale/700 | #3A3E47 | 카드 타이틀 |
| `Color.dsError200` | error/200 | #FFEBEB | 에러 배너 바탕 |
| `Color.dsError300` | error/300 | #FFA6A6 | 에러 배너 보더 |
| `Color.dsError500` | error/500 | #FF5757 | 에러 텍스트·스트립 |

## 규칙

- 새 색 추가: `Colors.xcassets` 에 colorset 추가 → `Color.load("Name")` 으로 토큰 노출 (design.md 에셋 로드 규칙). 직접 `Color(red:…)` 남발 금지.
- Figma 에서 변수 미바인딩 raw 값(예: 칩 보더 #EDEDED, 분석 밴드 #1A3C14)은 섣불리 토큰화하지 않는다 — 사용처 private 상수 + 주석으로 보류하고, 디자인 시스템에 변수가 생기면 승격.
- 이미지 토큰도 동일 seam: `Image.load(_:)` + `Image.DS` 네임스페이스 — icClose · icCancelMini · icCancelSmall · icInfo · icError · icSuccess · icUpload · imgTooltipTail.
