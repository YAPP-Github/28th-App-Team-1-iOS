# 입력 — 값을 바인딩으로 주고받는 위젯 + 그 주변 줄

필드·에디터·토글·체크박스, 그리고 필드 아래에 붙는 안내/에러 줄(`FieldSubText`·`InfoField`). 탭해서 액션만 내보내는 건 `button.md`.
**표는 이름 알파벳순으로 유지한다** — 새 행을 끝에 붙이지 말고 제자리에 끼워 넣는다(동시 추가 시 git 자동 병합).

| 컴포넌트 | Figma | API | 용도 |
|---|---|---|---|
| `FieldSubText` | text-sub 2044:1658 | `(_ text:, status: .info/.success/.error)` | 필드 아래 서브 텍스트 한 줄 — 아이콘 16 + `body6`, 말줄임. 판 없는 맨 줄(`InfoField` 와 구분). 아이콘·색은 status 에 묶어 닫음(info g300 / success g800 / error e500). `HilitTextField` 가 내장하므로 직접 조립은 드묾 |
| `HilitCheckboxStyle` | Checkbox 3768:16630 | `Toggle(isOn:) { EmptyView() }.toggleStyle(.hilitCheckbox)` | 체크박스 — 24×24 직각 박스. on 배경 b800 + `Image.Check.green` / off 배경 white + 테두리 1.6 g200 + `Image.Check.gray`(유령 체크). **커스텀 View 아님** — `HilitToggleStyle` 과 같은 이유, 탭은 내부 `Button` 이 받는다(pressed·disabled 공짜). 라벨은 박스 **오른쪽** p8(스위치와 반대 — 목록 행 관례)이고 같이 탭된다 |
| `HilitTextEditor` | text-field large 2091:806 | `(_ placeholder:, text: Binding<String>, maxLength:)` | 여러 줄 입력 박스 — 높이 158 고정(안에서 스크롤)·4변 테두리 1.2 g100·px16/py14. `maxLength` 주면 아래 오른쪽 «n/max» 카운터(`body9` g500) + 초과 잘라냄. 시안에 포커스 바·클리어·의미 상태 없음 — 그리지 않는다. SwiftUI `TextEditor` 와 이름 충돌로 `Hilit` 접두 |
| `HilitTextField` | text-field 2044:1801 (+카운터 조합 2044:1623) | `(_ placeholder:, text: Binding<String>, status: .idle/.loading(라벨)/.success/.error, subText:, maxLength:)` | 한 줄 입력 필드 — px16/py14·테두리 1.2 g100. **포커스·타이핑은 내부 파생**(포커스 = 아래 4pt g500 바, 글자 있으면 클리어 — 자리는 상시 확보), **의미 상태만 파라미터**. `.loading` 입력 잠금 + g100 판 + 라벨 + 무한 진행 바 / `.success`·`.error` 색 바 + `FieldSubText`. `subText` 는 포커스 중·loading 엔 숨김(시안). `maxLength` 는 카운터 + 잘라냄. SwiftUI `TextField` 와 이름 충돌로 `Hilit` 접두 |
| `HilitToggleStyle` | Toggle 2044:4999 | `Toggle(isOn:) { EmptyView() }.toggleStyle(.hilit)` | 스위치 토글 — 50×28 직각 트랙(g900) + 20×20 노브(on g500 / off g50). **커스텀 View 아님** — 배선·접근성은 `Toggle` 몫, 그림만 스타일. 라벨 넘기면 왼쪽 p8 (`labelsHidden()` 은 커스텀 스타일에 안 듣는다) |
| `InfoField` | info-field 2085:3925 | `(_ text:, style: .gray/.error)` | 입력·화면 아래 안내/에러 줄 — 원 안 i 아이콘 + 12pt, px14/py12·모서리 0. `.gray` g100 판 / `.error` e200 판 + e300 테두리 1.2. 아이콘은 판 색에 묶여 있다(시안 instance-swap 슬롯을 열지 않음), 폭은 호출부 몫 |
| `NameField` | name-field 2192:5331 | `(_ placeholder:, text: Binding<String>)` | 이름 한 줄 밑줄 입력란 — 24pt 중앙 정렬 + 4pt 밑줄. Figma `status` 축은 파라미터가 아니라 **`text.isEmpty` 에서 파생**(빈 값 g500·g100 / 입력됨 b800·g600). 폭은 내용 hug(밑줄이 글자를 따라감) — 가운데 정렬은 호출부 `.frame(maxWidth: .infinity)`. 포커스는 열지 않고 전송은 밖에서 `.onSubmit` |

## Figma 원본 불일치 — 디자이너 확인 대기

① `Checkbox` 의 꺼짐 변형 이름이 `status=Indeterminate`(세 번째 상태가 아니라 그냥 off) — off 로 구현했다. ② 같은 변형의 체크 위치가 켜짐보다 x·y 각 1.6 (= 테두리 두께) 위/왼쪽이다 — 테두리 안쪽 기준으로 놓인 실수로 보고 두 상태 모두 켜짐 위치(가로 정중앙)로 맞췄다. ③ `text-field` 의 loading 라벨(«분석 중») 색이 컴포넌트 세트(2044:1798)는 g400 인데 카운터 조합 예시(2286:5661)는 g900 — 세트 쪽(g400)으로 구현했다. ④ `text-field` 두 패밀리의 패딩이 상충한다 — `435:1603`(small/large)은 네 변 p14, `435:1630`(case 패밀리)은 px16/py14. 코드는 case 패밀리를 따른다(현행 유지).
