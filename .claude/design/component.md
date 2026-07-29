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
| `CountdownCard` | countdown-card 3165:14623 | `(title:subtitle:time:status: .active/.ended)` | 남은 시간 다크 카드 — b800 판 p12, 제목+쉐브론 / g700 1pt 선 / 스톱워치 24 + 보조 문구(#D2D6DE 80%) + 시간 `sub3`. 상태가 글자·아이콘 색을 함께 옮긴다(`.ended` g300 + disabled 아이콘). **탭 없음** — 목적지가 화면마다 달라 호출부가 `Button`으로 감싼다. 폭은 호출부 몫 |
| `DashIndicator` | dash 2044:4712 | `(count:current:)` | 진행 단계 대시 — 20×4 조각(on b800 / off g50) 나열. 조각 단독 공개 없음, «몇 번째까지 켜는가» 규칙만 갖는다 |
| `FieldSubText` | text-sub 2044:1658 | `(_ text:, status: .info/.success/.error)` | 필드 아래 서브 텍스트 한 줄 — 아이콘 16 + `body6`, 말줄임. 판 없는 맨 줄(`InfoField` 와 구분). 아이콘·색은 status 에 묶어 닫음(info g300 / success g800 / error e500). `HilitTextField` 가 내장하므로 직접 조립은 드묾 |
| `HighlightedText` | highlighted-text | `(_ text:, typography:, alignment:, plainForeground:)` + 체인 `.hilight(_:)`·`.hilightColor(_:)`·`.hilightFill(_:)`·`.hilightIcon(_:)`·`.hilightColors(foreground:background:)` | 형광펜 마커. **문장 전체를 넘기고 `.hilight("부분")`** — 미지정 시 전체 강조. `hilightColor` 6종(green/black/gray/blue/red/none)은 글자색+배경색 한 쌍. `hilightFill` 3종(full/midlined/underlined), 띠 두께는 `typography` 파생(≥20pt 12, 아니면 8). `Text` 확장은 불가 — 내부 문자열을 못 꺼낸다. `alignment` 는 넘친 줄을 **줄마다** 미는 것이라 호출부가 폭을 줘야 보인다 |
| `HilitCheckboxStyle` | Checkbox 3768:16630 | `Toggle(isOn:) { EmptyView() }.toggleStyle(.hilitCheckbox)` | 체크박스 — 24×24 직각 박스. on 배경 b800 + `Image.Check.green` / off 배경 white + 테두리 1.6 g200 + `Image.Check.gray`(유령 체크). **커스텀 View 아님** — `HilitToggleStyle` 과 같은 이유, 탭은 내부 `Button` 이 받는다(pressed·disabled 공짜). 라벨은 박스 **오른쪽** p8(스위치와 반대 — 목록 행 관례)이고 같이 탭된다 |
| `HilitNavigationBar` | Navigationbar — icon 2446:7485 · text 3029:11189 · logo 3632:13967 | **화면 부착은 모디파이어**: `.hilitNavigationBar("타이틀", leading: .icon(Image…){…}, trailing: .icon/.text(…){…}, background:)` · logo 변형 `.hilitLogoNavigationBar(trailing:)`. View 직접 배치도 가능(`HilitNavigationBar(…)` / `.logo(trailing:)`) | 커스텀 내비바 — h54(슬롯 26+py14)·px20. 아이콘 슬롯 폭 40 고정(비어도 유지 — 타이틀 중앙 보존), 텍스트 버튼은 trailing 전용(DEBUG assert)·hug. 시안 show 토글 = 슬롯 `nil`. 모디파이어가 배관(safeAreaInset·시스템 바 숨김·backButtonHidden) 소유. backButtonHidden 이 끄는 스와이프백은 `Interaction/UINavigationController+SwipeBack.swift` 가 전역 복구(루트·전환중 가드) — push 화면은 leading `Image.Left.*` 버튼을 보이는 어포던스로 병행. 스와이프로 pop 되면 안 되는 화면(온보딩 스텝처럼 pop 이 리듀서 로직과 묶인 곳)은 `allowsSwipeBack: false`. `background` 는 화면 배경 토큰과 맞춘다(다크 화면 = b800 + white 아이콘). View 단독은 배경 안 그림 |
| `HilitTextEditor` | text-field large 2091:806 | `(_ placeholder:, text: Binding<String>, maxLength:)` | 여러 줄 입력 박스 — 높이 158 고정(안에서 스크롤)·4변 테두리 1.2 g100·px16/py14. `maxLength` 주면 아래 오른쪽 «n/max» 카운터(`body9` g500) + 초과 잘라냄. 시안에 포커스 바·클리어·의미 상태 없음 — 그리지 않는다. SwiftUI `TextEditor` 와 이름 충돌로 `Hilit` 접두 |
| `HilitTextField` | text-field 2044:1801 (+카운터 조합 2044:1623) | `(_ placeholder:, text: Binding<String>, status: .idle/.loading(라벨)/.success/.error, subText:, maxLength:)` | 한 줄 입력 필드 — px16/py14·테두리 1.2 g100. **포커스·타이핑은 내부 파생**(포커스 = 아래 4pt g500 바, 글자 있으면 클리어 — 자리는 상시 확보), **의미 상태만 파라미터**. `.loading` 입력 잠금 + g100 판 + 라벨 + 무한 진행 바 / `.success`·`.error` 색 바 + `FieldSubText`. `subText` 는 포커스 중·loading 엔 숨김(시안). `maxLength` 는 카운터 + 잘라냄. SwiftUI `TextField` 와 이름 충돌로 `Hilit` 접두 |
| `HilitToggleStyle` | Toggle 2044:4999 | `Toggle(isOn:) { EmptyView() }.toggleStyle(.hilit)` | 스위치 토글 — 50×28 직각 트랙(g900) + 20×20 노브(on g500 / off g50). **커스텀 View 아님** — 배선·접근성은 `Toggle` 몫, 그림만 스타일. 라벨 넘기면 왼쪽 p8 (`labelsHidden()` 은 커스텀 스타일에 안 듣는다) |
| `InfoField` | info-field 2085:3925 | `(_ text:, style: .gray/.error)` | 입력·화면 아래 안내/에러 줄 — 원 안 i 아이콘 + 12pt, px14/py12·모서리 0. `.gray` g100 판 / `.error` e200 판 + e300 테두리 1.2. 아이콘은 판 색에 묶여 있다(시안 instance-swap 슬롯을 열지 않음), 폭은 호출부 몫 |
| `Modal` | modal 2302:6098 | `(_ text:, subText:, icon:, info:) { ButtonLarge(.modal, …) }` | 모달 카드 — 흰 판(px24·py40·gap20) + 하단 버튼 슬롯. Figma `showIcon`·`showSubText`·`showInfoField` 축은 **파라미터 nil** 로 표현. 아이콘은 열린 슬롯(모달마다 다른 일러스트가 실재 — `InfoField` 와 반대), 안내줄은 `InfoField(.gray)` 고정. 폭·딤 배경·표시 전환은 호출부 몫(카드만 그린다) |
| `NameField` | name-field 2192:5331 | `(_ placeholder:, text: Binding<String>)` | 이름 한 줄 밑줄 입력란 — 24pt 중앙 정렬 + 4pt 밑줄. Figma `status` 축은 파라미터가 아니라 **`text.isEmpty` 에서 파생**(빈 값 g500·g100 / 입력됨 b800·g600). 폭은 내용 hug(밑줄이 글자를 따라감) — 가운데 정렬은 호출부 `.frame(maxWidth: .infinity)`. 포커스는 열지 않고 전송은 밖에서 `.onSubmit` |
| `Parallelogram` | highlighted-text 배경 | `Shape` — `(slant:)` | 하이라이트 배경 Shape. 직접 쓰기보다 `HighlightedText` 우선 |
| `QuoteField` | quote-field 1984:7003 | `(_ text:, style: .gray/.greenOnDark/.block, onEdit:)` | 작성된 코멘트 인용 줄 — 세로 바 + 한 줄(말줄임). **입력 위젯 아님**(커서·placeholder 상태 없음), 편집은 `.block` 의 «수정» 링크가 밖으로 넘긴다. `onEdit` 은 `.block` 전용(DEBUG assert) |
| `SaveIndicator` | tag-with-icon 2555:7558 | `(.saving / .saved)` | 자동 저장 상태 — 스피너 «저장 중 ...» / 체크 «저장됨» |
| `TabSelector` | tab 2044:4765 | `(_ items: [Item], selection: Binding<Tag>, layout: .hug/.fill)` · `Item(tag:title:isEnabled:)` | 밑줄 텍스트 탭 줄 — h38·px14/py8, 선택 시 아래 1.5 밑줄(b800). 상태는 **selection 바인딩에서 파생**(선택된 하나만 밑줄), 비활성은 `isEnabled: false`(글자 g500). 탭 조각 단독 공개 없음. 시안에 줄 배치가 없어 항목 간 간격 0 |
| `TagLabel` | tag 1941:7132 | `(_ text:, foreground:, background:)` (기본 회색) | 소형 사각 태그 — «선택» 안내, 척도 극 라벨. 시안은 12변형 2 family — `padding=0px`(px4·`body6` m14) / `4px`(px12+py4·`body5` sb14, outlined·배경없음 포함). **구현은 0px family 만**(px4·`body6` m14 — 2026-07-30 에 `.body8` 오구현 정정, 사고 사례 9번). 색이 열린 파라미터라 시안에 없는 조합도 만들어진다 — `Style` enum 으로 닫는 게 맞다 |
| `TitleBox` | title-box 2094:7912 · title 2044:1856 | `(_ lines: [Line], tag:, sub:, alignment:)` · `Line(_ text:, highlight:)` | 화면 머리글 — «뱃지 8 타이틀 4 서브» 수직 리듬. 타이틀 줄은 `head3` + 그린 마커(`HighlightedText`), 뱃지는 `TagLabel`(b800/g500), 서브는 `body4`. Figma `status` 축 = `alignment`, `light/dark` 축 = `.hilitSurface(_:)`(판은 화면 속성), `show*` 축 = 값의 유무. `Line` 은 문자열 리터럴로도 쓴다(마커 없는 줄). **시안의 좌우 px20 은 뺐다** — 화면이 이미 콘텐츠 열에 20 을 줘서 겹친다. 폭은 호출부 몫 |

> **Figma 원본 불일치 — 디자이너 확인 대기.** ① `bubble-field` 의 dark 변형 이름이 `status=status5`(mini 여야 함)이고, `mood` 축은 mini 에만 실재한다(wide 는 light 뿐) — 시안대로 구현했다. ② `Checkbox` 의 꺼짐 변형 이름이 `status=Indeterminate`(세 번째 상태가 아니라 그냥 off) — off 로 구현했다. ③ 같은 변형의 체크 위치가 켜짐보다 x·y 각 1.6 (= 테두리 두께) 위/왼쪽이다 — 테두리 안쪽 기준으로 놓인 실수로 보고 두 상태 모두 켜짐 위치(가로 정중앙)로 맞췄다. ④ `countdown-card` 제목 타이포가 상태마다 다르다(`active` sb16 / `end` sb18) — 실수로 보이지만 시안대로 구현했다. 보조 문구 색 변수명은 `Gray scale/300`(#D2D6DE)인데 팔레트의 `grayscale/gray-300` 은 #9DA0AC 다 — 팔레트 밖 값이라 파일 내부 private 상수로 보류. ⑤ `modal` 제목도 같은 레거시 컬렉션(`Gray scale/800` = #262A30)을 쓴다 — 이름상 800(#31333B)과 어긋나지만 값이 `g900`(#27282F)과 사실상 동일(Δ≤2)해서 이쪽은 토큰으로 흡수했다(④ 는 팔레트 밖이라 보류, 이건 근사 범위 안). ⑥ `text-field` 의 loading 라벨(«분석 중») 색이 컴포넌트 세트(2044:1798)는 g400 인데 카운터 조합 예시(2286:5661)는 g900 — 세트 쪽(g400)으로 구현했다.

## 승격 규칙 (Feature → Shared)

세 조건을 모두 만족할 때만 승격한다: ① Figma 에서 이름 붙은 DS 컴포넌트와 1:1 ② 도메인 타입·스토어 무의존(primitive 파라미터만) ③ 두 번째 사용처가 실재. 승격 시 도메인 어휘를 뺀 중립 이름으로 바꾸고 시각 값은 그대로 옮긴다(픽셀 동일).
