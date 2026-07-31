# 버튼 — 탭하면 액션이 실행되는 컴포넌트

`ButtonLarge`(View) + ButtonStyle 4종 + 환경 모디파이어. 값을 바인딩으로 주고받는 위젯은 여기 아니라 `input.md`.
**경계 규칙: 레이아웃·슬롯을 소유하면 View, `Button` 하나를 스킨하면 ButtonStyle.**

전 티어 공통 — 모서리 0(캡슐 아님) · 색은 팔레트 23색 안 · 아이콘은 축이 아니라 **라벨 구성**(호출부가 조립).
**상태는 넘기지 않는다** — pressed·disabled 는 `configuration.isPressed`/`@Environment(\.isEnabled)` 가 자동 처리하고, disabled 는 어떤 색이든 같은 룩으로 수렴한다.

## 티어 카탈로그

Figma 버튼 6종을 옮긴 체계. (이 표만 알파벳순이 아니다 — 크기 티어 순서(large→medium→mini→sub→tag)가 정보라서. 닫힌 카탈로그라 행이 늘 일도 거의 없다.)

| 대상 | Figma | API | 비고 |
|---|---|---|---|
| `ButtonLarge` 단일 | ButtonLarge_bottom 1941:3256 · _modal 2302:5987 | `ButtonLarge(_ title:, _ kind: .bottom/.modal, style: .filled/.outlined, action:)` | h55·sub7. bottom = px24·pt22/pb10·배경이 안전영역까지 / modal = px8·py16. `.outlined` 는 bottom 전용(DEBUG assert) |
| `ButtonLarge` 2버튼 | bottom/filled-2 · modal/dubble | `ButtonLarge(_ kind:, tone: .dark/.gray/.twoColor) { } trailing: { }` | divider 1×25. **한쪽만 비활성은 그 자식에 `.disabled(true)`** — 별도 변형 없음. `.gray` 는 bottom 전용. **modal+twoColor 는 패딩 0 풀블리드** — 좌 g50·우 b800 반반이 카드 바닥을 꽉 채운다(«modal» 2555:7739), 세로 여백 16 은 세그먼트 배경 안 |
| `.medium(_:layout:)` | ButtonMedium 1941:3261 | `.buttonStyle(.medium(.green))` · `.medium(.blue, layout: .fill)` | h45·py12. 색 6종 default/black/gray/green/blue/red. `layout` — `.hug` px24(기본) / `.fill` 등폭(가로패딩 0, 넘치면 축소) → HStack 에 나란히 놓아 **N지선다 척도 칩** |
| `.mini(_:layout:)` | ButtonMini 1941:6780 · with-icon 2227:4441 | `.buttonStyle(.mini(.gray, layout: .withIcon))` | h34·py8·hug. 색 5종. 가로 여백은 `layout` — textOnly px12 / withIcon px8 |
| `.miniSub(_:)` | ButtonMini status=sub | `.buttonStyle(.miniSub(.white))` | h26·px8/py4·테두리 1.0. 색 3종 white/black/none |
| `.tag(_:)` | ButtonTag 1941:6762 | `.buttonStyle(.tag(.selected))` | h29·px12/py4. 3상태 default/selected/completed — selected 는 Bold, completed 는 opacity 20% |
| `.hilitSurface(_:)` | `light/dark` 축 | `VStack { … }.hilitSurface(.dark)` | 화면이 한 번 선언 → 하위 `.mini` 팔레트 전환. 버튼 속성이 아니라 화면 속성이라 Environment |
| `.hilitButtonLoading(_:)` | **시안에 없음** | `ButtonLarge(…).hilitButtonLoading(true)` | 라벨을 감추고 스피너를 얹어 폭 유지 + 탭 차단. 앱 사정이라 Figma 에서 찾지 말 것 — 화면에서 만들 수 없어(밖에서 `.opacity` 를 걸면 배경까지 사라짐) DS 에 둔다 |

## 규칙을 가진 래퍼

**설탕 래퍼를 두지 않는다.** 스타일을 그대로 쓴다 — 인자만 옮겨 담는 래퍼는 이름만 하나 더 외우게 한다.
감싸는 타입은 **«규칙»을 가질 때만** 만든다. 외형만 바꾸는 건 스타일 파라미터로 충분하다.
**이 표는 이름 알파벳순으로 유지한다** — 새 행을 끝에 붙이지 말고 제자리에 끼워 넣는다(동시 추가 시 git 자동 병합).

| 컴포넌트 | Figma | API | 갖는 규칙 |
|---|---|---|---|
| `ChoiceChip` | button-medium 2150:7297 | `(_ label:, isSelected:, tone: .positive/.negative, action:)` | N지선다 등폭 척도 칩 — HStack 에 나란히. 외형은 `.medium(layout: .fill)` 이 그리고, 이 타입은 **«선택 상태 → 톤»** 규칙만 갖는다 |

## Figma 원본 불일치 — 디자이너 확인 대기

① `bottom/filled-2/gray` 라벨은 b800 인데 `2color` 왼쪽 라벨은 g700(같은 g50 배경) ② `modal/dubble-button/1color` 세로 padding 15(나머지 modal 전부 16 — 오타로 보고 16 구현) ③ `Medium/black` 은 `status=outlined` 인데 테두리 없음. 셋 다 시안대로 구현했다.
