# 공용 컴포넌트 — SharedDesignSystem/Interface/Component/

파일 하나당 컴포넌트 하나, 전부 `public` + `#Preview`. 독스트링에 Figma 컴포넌트 노드 근거 보존. **커스텀 UI 를 새로 만들기 전에 이 목록을 먼저 검토한다.** 단일 소스는 코드 — 표와 어긋나면 코드가 우선.

## 버튼 — ButtonLarge(View) + ButtonStyle 4종

Figma 버튼 6종을 옮긴 체계. **경계 규칙: 레이아웃·슬롯을 소유하면 View, Button 하나를 스킨하면 ButtonStyle.**
전 티어 공통 — 모서리 0(캡슐 아님) · 색은 팔레트 23색 안 · 아이콘은 축이 아니라 **라벨 구성**(호출부가 조립).
**상태는 넘기지 않는다** — pressed·disabled 는 `configuration.isPressed`/`@Environment(\.isEnabled)` 가 자동 처리하고, disabled 는 어떤 색이든 같은 룩으로 수렴한다.
(이 표만 알파벳순이 아니다 — 크기 티어 순서(large→medium→mini→sub→tag)가 정보라서. 닫힌 카탈로그라 행이 늘 일도 거의 없다.)

| 대상 | Figma | API | 비고 |
|---|---|---|---|
| `ButtonLarge` 단일 | ButtonLarge_bottom 1941:3256 · _modal 2302:5987 | `ButtonLarge(_ title:, _ kind: .bottom/.modal, style: .filled/.outlined, action:)` | h55·sub7. bottom = px24·pt22/pb10·배경이 안전영역까지 / modal = px8·py16. `.outlined` 는 bottom 전용(DEBUG assert) |
| `ButtonLarge` 2버튼 | bottom/filled-2 · modal/dubble | `ButtonLarge(_ kind:, tone: .dark/.gray/.twoColor) { } trailing: { }` | divider 1×25. **한쪽만 비활성은 그 자식에 `.disabled(true)`** — 별도 변형 없음. `.gray` 는 bottom 전용 |
| `.medium(_:layout:)` | ButtonMedium 1941:3261 | `.buttonStyle(.medium(.green))` · `.medium(.blue, layout: .fill)` | h45·py12. 색 6종 default/black/gray/green/blue/red. `layout` — `.hug` px24(기본) / `.fill` 등폭(가로패딩 0, 넘치면 축소) → HStack 에 나란히 놓아 **N지선다 척도 칩** |
| `.mini(_:layout:)` | ButtonMini 1941:6780 · with-icon 2227:4441 | `.buttonStyle(.mini(.gray, layout: .withIcon))` | h34·py8·hug. 색 5종. 가로 여백은 `layout` — textOnly px12 / withIcon px8 |
| `.miniSub(_:)` | ButtonMini status=sub | `.buttonStyle(.miniSub(.white))` | h26·px8/py4·테두리 1.0. 색 3종 white/black/none |
| `.tag(_:)` | ButtonTag 1941:6762 | `.buttonStyle(.tag(.selected))` | h29·px12/py4. 3상태 default/selected/completed — selected 는 Bold, completed 는 opacity 20% |
| `.hilitSurface(_:)` | `light/dark` 축 | `VStack { … }.hilitSurface(.dark)` | 화면이 한 번 선언 → 하위 `.mini` 팔레트 전환. 버튼 속성이 아니라 화면 속성이라 Environment |
| `.hilitButtonLoading(_:)` | **시안에 없음** | `ButtonLarge(…).hilitButtonLoading(true)` | 라벨을 감추고 스피너를 얹어 폭 유지 + 탭 차단. 앱 사정이라 Figma 에서 찾지 말 것 — 화면에서 만들 수 없어(밖에서 `.opacity` 를 걸면 배경까지 사라짐) DS 에 둔다 |

**설탕 래퍼를 두지 않는다.** 스타일을 그대로 쓴다 — 인자만 옮겨 담는 래퍼는 이름만 하나 더 외우게 한다.
감싸는 타입은 **«규칙»을 가질 때만** 만든다(예: `ChoiceChip` 은 «선택 상태 → 어떤 톤» 을 안다). 외형만 바꾸는 건 스타일 파라미터로 충분하다.

> **Figma 원본 불일치 — 디자이너 확인 대기.** ① `bottom/filled-2/gray` 라벨은 b800 인데 `2color` 왼쪽 라벨은 g700(같은 g50 배경) ② `modal/dubble-button/1color` 세로 padding 15(나머지 modal 전부 16 — 오타로 보고 16 구현) ③ `Medium/black` 은 `status=outlined` 인데 테두리 없음. 셋 다 시안대로 구현했다.

## 그 밖의 컴포넌트

**표는 이름 알파벳순으로 유지한다.** 새 컴포넌트를 끝에 붙이지 말고 제자리에 끼워 넣는다 — 둘이 동시에 추가해도 서로 다른 줄에 들어가 git 이 알아서 병합한다(끝에 붙이면 같은 자리라 충돌).

| 컴포넌트 | Figma | API | 용도 |
|---|---|---|---|
| `BubbleField` | bubble-field 2000:7532 | `(_ message:, _ kind: .wide(tail: .none/.top/.bottom) / .mini(mood: .light/.dark))` | 말풍선 — `.wide` 폭 274·py12(꼬리 top 은 좌상단, bottom 은 우하단) / `.mini` 내용폭·py8·꼬리 좌하단. 꼬리 17×11, 붙는 변 모서리에서 40 안쪽. 꼬리 없는 `.wide(tail: .none)`(기본)이 토스트 — 위치·해제 타이밍은 호출부 |
| `ChoiceChip` | button-medium 2150:7297 | `(_ label:, isSelected:, tone: .positive/.negative, action:)` | N지선다 등폭 척도 칩 — HStack 에 나란히. 외형은 `.medium(layout: .fill)` 이 그리고, 이 타입은 **«선택 상태 → 톤»** 규칙만 갖는다 |
| `DashIndicator` | dash 2044:4712 | `(count:current:)` | 진행 단계 대시 — 20×4 조각(on b800 / off g50) 나열. 조각 단독 공개 없음, «몇 번째까지 켜는가» 규칙만 갖는다 |
| `HighlightedText` | highlighted-text | `(_ text:, typography:, plainForeground:)` + 체인 `.hilight(_:)`·`.hilightColor(_:)`·`.hilightFill(_:)`·`.hilightIcon(_:)`·`.hilightColors(foreground:background:)` | 형광펜 마커. **문장 전체를 넘기고 `.hilight("부분")`** — 미지정 시 전체 강조. `hilightColor` 6종(green/black/gray/blue/red/none)은 글자색+배경색 한 쌍. `hilightFill` 3종(full/midlined/underlined), 띠 두께는 `typography` 파생(≥20pt 12, 아니면 8). `Text` 확장은 불가 — 내부 문자열을 못 꺼낸다 |
| `HilitToggleStyle` | Toggle 2044:4999 | `Toggle(isOn:) { EmptyView() }.toggleStyle(.hilit)` | 스위치 토글 — 50×28 직각 트랙(g900) + 20×20 노브(on g500 / off g50). **커스텀 View 아님** — 배선·접근성은 `Toggle` 몫, 그림만 스타일. 라벨 넘기면 왼쪽 p8 (`labelsHidden()` 은 커스텀 스타일에 안 듣는다) |
| `Parallelogram` | highlighted-text 배경 | `Shape` — `(slant:)` | 하이라이트 배경 Shape. 직접 쓰기보다 `HighlightedText` 우선 |
| `QuoteField` | quote-field 1984:7003 | `(_ text:, style: .gray/.greenOnDark/.block, onEdit:)` | 작성된 코멘트 인용 줄 — 세로 바 + 한 줄(말줄임). **입력 위젯 아님**(커서·placeholder 상태 없음), 편집은 `.block` 의 «수정» 링크가 밖으로 넘긴다. `onEdit` 은 `.block` 전용(DEBUG assert) |
| `SaveIndicator` | tag-with-icon 2555:7558 | `(.saving / .saved)` | 자동 저장 상태 — 스피너 «저장 중 ...» / 체크 «저장됨» |
| `TabSelector` | tab 2044:4765 | `(_ items: [Item], selection: Binding<Tag>, layout: .hug/.fill)` · `Item(tag:title:isEnabled:)` | 밑줄 텍스트 탭 줄 — h38·px14/py8, 선택 시 아래 1.5 밑줄(b800). 상태는 **selection 바인딩에서 파생**(선택된 하나만 밑줄), 비활성은 `isEnabled: false`(글자 g500). 탭 조각 단독 공개 없음. 시안에 줄 배치가 없어 항목 간 간격 0 |
| `TagLabel` | tag | `(_ text:, foreground:, background:)` (기본 회색) | 소형 사각 태그 — «선택» 안내, 척도 극 라벨 |

> **Figma 원본 불일치 — 디자이너 확인 대기.** `bubble-field` 의 dark 변형 이름이 `status=status5`(mini 여야 함)이고, `mood` 축은 mini 에만 실재한다(wide 는 light 뿐) — 시안대로 구현했다.

## 승격 규칙 (Feature → Shared)

세 조건을 모두 만족할 때만 승격한다: ① Figma 에서 이름 붙은 DS 컴포넌트와 1:1 ② 도메인 타입·스토어 무의존(primitive 파라미터만) ③ 두 번째 사용처가 실재. 승격 시 도메인 어휘를 뺀 중립 이름으로 바꾸고 시각 값은 그대로 옮긴다(픽셀 동일).
