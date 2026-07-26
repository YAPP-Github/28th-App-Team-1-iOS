# 공용 컴포넌트 — SharedDesignSystem/Interface/Component/

파일 하나당 컴포넌트 하나, 전부 `public` + `#Preview`. 독스트링에 Figma 컴포넌트 노드 근거 보존. **커스텀 UI 를 새로 만들기 전에 이 목록을 먼저 검토한다.** 단일 소스는 코드 — 표와 어긋나면 코드가 우선.

| 컴포넌트 | Figma | API | 용도 |
|---|---|---|---|
| `PrimaryButton` | button-large 2091:4488 | `(_ title:, isLoading:, action:)` | 하단 도킹 풀블리드 CTA — 배경이 세이프에어리어까지 번짐. 비활성은 호출부 `.disabled` |
| `ModalButton` | button-large/modal 2302:5985 | `(_ title:, action:)` | 모달/카드 내부 풀폭 CTA — py16 대칭, 배경 번짐 없음 |
| `MiniButton` | button-mini/with-icon 2227:4448 | `(_ title:, systemImage:, action:)` | 섹션 우측 보조 액션 (예: «영상 다시보기») |
| `ChoiceChip` | button-medium 2150:7297 | `(_ label:, isSelected:, tone: .positive/.negative, action:)` | N지선다 등폭 척도 칩 — HStack 에 나란히 |
| `TagLabel` | tag | `(_ text:, foreground:, background:)` (기본 회색) | 소형 사각 태그 — «선택» 안내, 척도 극 라벨 |
| `BubbleToast` | BubbleField 2555:7543 | `(_ message:)` | 폭 274 고정 블랙 토스트 — 위치·해제 타이밍은 호출부 |
| `SaveIndicator` | tag-with-icon 2555:7558 | `(.saving / .saved)` | 자동 저장 상태 — 스피너 «저장 중 ...» / 체크 «저장됨» |
| `HighlightedText` | highlighted-text | `(_ text:, typography:, plainForeground:)` + 체인 `.hilight(_:)`·`.hilightColor(_:)`·`.hilightFill(_:)`·`.hilightIcon(_:)`·`.hilightColors(foreground:background:)` | 형광펜 마커. **문장 전체를 넘기고 `.hilight("부분")`** — 미지정 시 전체 강조. `hilightColor` 6종(green/black/gray/blue/red/none)은 글자색+배경색 한 쌍. `hilightFill` 3종(full/midlined/underlined), 띠 두께는 `typography` 파생(≥20pt 12, 아니면 8). `Text` 확장은 불가 — 내부 문자열을 못 꺼낸다 |
| `Parallelogram` | highlighted-text 배경 | `Shape` — `(slant:)` | 하이라이트 배경 Shape. 직접 쓰기보다 `HighlightedText` 우선 |

## 승격 규칙 (Feature → Shared)

세 조건을 모두 만족할 때만 승격한다: ① Figma 에서 이름 붙은 DS 컴포넌트와 1:1 ② 도메인 타입·스토어 무의존(primitive 파라미터만) ③ 두 번째 사용처가 실재. 승격 시 도메인 어휘를 뺀 중립 이름으로 바꾸고 시각 값은 그대로 옮긴다(픽셀 동일).
