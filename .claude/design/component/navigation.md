# 내비게이션 — 화면 전환·진행 위치를 다루는 컴포넌트

내비바·탭 줄·단계 인디케이터. 값을 바인딩으로 받아도(예: `TabSelector` 의 `selection`) **화면·영역 전환이 목적이면 여기**다.
**표는 이름 알파벳순으로 유지한다** — 새 행을 끝에 붙이지 말고 제자리에 끼워 넣는다(동시 추가 시 git 자동 병합).

| 컴포넌트 | Figma | API | 용도 |
|---|---|---|---|
| `DashIndicator` | dash 2044:4712 | `(count:current:)` | 진행 단계 대시 — 20×4 조각(on b800 / off g50) 나열. 조각 단독 공개 없음, «몇 번째까지 켜는가» 규칙만 갖는다 |
| `HilitNavigationBar` | Navigationbar — icon 2446:7485 · text 3029:11189 · logo 3632:13967 | **화면 부착은 모디파이어**: `.hilitNavigationBar("타이틀", leading: .icon(Image…){…}, trailing: .icon/.text(…){…}, background:)` · logo 변형 `.hilitLogoNavigationBar(trailing:)`. View 직접 배치도 가능(`HilitNavigationBar(…)` / `.logo(trailing:)`) | 커스텀 내비바 — h54(슬롯 26+py14)·px20. 아이콘 슬롯 폭 40 고정(비어도 유지 — 타이틀 중앙 보존), 텍스트 버튼은 trailing 전용(DEBUG assert)·hug. 시안 show 토글 = 슬롯 `nil`. 모디파이어가 배관(safeAreaInset·시스템 바 숨김·backButtonHidden) 소유. backButtonHidden 이 끄는 스와이프백은 `Interaction/UINavigationController+SwipeBack.swift` 가 전역 복구(루트·전환중 가드) — push 화면은 leading `Image.Left.*` 버튼을 보이는 어포던스로 병행. 스와이프로 pop 되면 안 되는 화면(온보딩 스텝처럼 pop 이 리듀서 로직과 묶인 곳)은 `allowsSwipeBack: false`. `background` 는 화면 배경 토큰과 맞춘다(다크 화면 = b800 + white 아이콘). View 단독은 배경 안 그림 |
| `TabSelector` | tab 2044:4765 | `(_ items: [Item], selection: Binding<Tag>, layout: .hug/.fill)` · `Item(tag:title:isEnabled:)` | 밑줄 텍스트 탭 줄 — h38·px14/py8, 선택 시 아래 1.5 밑줄(b800). 상태는 **selection 바인딩에서 파생**(선택된 하나만 밑줄), 비활성은 `isEnabled: false`(글자 g500). 탭 조각 단독 공개 없음. 시안에 줄 배치가 없어 항목 간 간격 0 |
