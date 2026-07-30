# 내비게이션 — 화면 전환·진행 위치를 다루는 컴포넌트

내비바·탭 줄·단계 인디케이터. 값을 바인딩으로 받아도(예: `TabSelector` 의 `selection`) **화면·영역 전환이 목적이면 여기**다.
**표는 이름 알파벳순으로 유지한다** — 새 행을 끝에 붙이지 말고 제자리에 끼워 넣는다(동시 추가 시 git 자동 병합).

| 컴포넌트 | Figma | API | 용도 |
|---|---|---|---|
| `DashIndicator` | dash 2044:4712 | `(count:current:)` | 진행 단계 대시 — 20×4 조각(on b800 / off g50) 나열. 조각 단독 공개 없음, «몇 번째까지 켜는가» 규칙만 갖는다 |
| `HilitNavigationBar` | Navigationbar — icon 2446:7485 · text 3029:11189 · logo 3632:13967 | **화면 부착은 모디파이어**: `.hilitNavigationBar("타이틀", trailing: .plus{…}/.text("버튼"){…}, theme: .light/.dark, background: .transparent/.filled, allowsSwipeBack:, onClose: {…})` · logo 변형 `.hilitLogoNavigationBar(onProfile:)`. View 직접 배치도 가능(`HilitNavigationBar(…)` / `.logo(onProfile:)`) | 커스텀 내비바 — h54(슬롯 26+py14)·px20. **뒤로 버튼 없음 — leading X 고정**이라 슬롯이 아니라 `onClose` 액션(최종 시안: X 통일, 뒤로는 하단 CTA·스와이프백 몫). `onClose` 생략 = 기본 동작(pop, 없으면 dismiss), 클로저 전달 = override — 아래 «닫기(X) 기본값과 override» 참조. 아이콘 슬롯 폭 40 고정(비어도 유지 — 타이틀 중앙 보존), 텍스트 버튼 hug. 시안 show 토글 = `trailing: nil`. `theme` 이 아이콘 색변형(`default24`/`white24`)·타이틀색·`.filled` 배경색(white/b800)을 전부 파생 — 다크에 검정 X 같은 조합 표현 불가. mini 버튼의 `.hilitSurface` 와 같은 «판 톤» 축이지만 내비바는 파라미터(명시가 안전). 다크 trailing 은 시안 없음(DEBUG assert). `background` 기본 `.transparent`(영상 풀블리드 — 콘텐츠 쪽 `.ignoresSafeArea()` 로 바 밑까지 깔림), 스크롤 화면은 `.filled`. 모디파이어가 배관(safeAreaInset·시스템 바 숨김·backButtonHidden·스와이프백 delegate) 소유 — backButtonHidden 이 끄는 스와이프백은 `Interaction/UINavigationController+SwipeBack.swift` 의 `SwipeBackPolicy` 가 **화면이 보이는 동안만 delegate 점유 후 반환**(전역 아님 — 시스템 피커 오염 방지). pop 전에 되물을 게 있는 화면만 `allowsSwipeBack: false`(상태 파생 값 가능). 스와이프 pop 은 리듀서에 `popFrom(id:)` 로 도착(`backRequested` 아님). View 단독은 배경 안 그림 |
| `TabSelector` | tab 2044:4765 | `(_ items: [Item], selection: Binding<Tag>, layout: .hug/.fill)` · `Item(tag:title:isEnabled:)` | 밑줄 텍스트 탭 줄 — h38·px14/py8, 선택 시 아래 1.5 밑줄(b800). 상태는 **selection 바인딩에서 파생**(선택된 하나만 밑줄), 비활성은 `isEnabled: false`(글자 g500). 탭 조각 단독 공개 없음. 시안에 줄 배치가 없어 항목 간 간격 0 |

## 닫기(X) 기본값과 override

X 의 기본 동작은 «이 화면 나가기» — `onClose` 를 생략하면 내비바가 `@Environment(\.dismiss)` 를 부른다(스택에 있으면 pop, present 됐으면 dismiss — SwiftUI 가 자동 분기). 어느 쪽이든 리듀서에는 `popFrom(id:)`/`PresentationAction.dismiss` 액션으로 도착하므로 상태를 우회하지 않는다.

**override** — 닫기 의미가 다르거나(플로우 전체 종료) 닫기 전에 되물어야 하는 화면은 클로저를 넘겨 리듀서가 소유한다. TCA 에서 가로채기 지점은 메서드 재정의가 아니라 리듀서 switch 다:

```swift
// ① 플로우 종료 override — 온보딩 스텝 (X = 위저드 전체 종료, delegate 로 코디네이터가 dismiss)
.hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })

// ② 확인 팝업 override — 닫기 전 되묻기 (팝업 시안 생기면 이 패턴대로)
case .view(.userTappedClose):
    state.exitConfirm = ConfirmationDialogState { TextState("작성 중인 내용이 사라져요") … }
    return .none
case .exitConfirm(.presented(.confirmExit)):
    return .run { _ in await dismiss() }        // @Dependency(\.dismiss) — 자기 present 형태에 맞게 pop/dismiss
```

스와이프백도 같은 원리의 «나가기» 경로지만 override 가 불가능하다(제스처 시작을 되물을 수 없음) — 그래서 확인이 필요한 화면은 `allowsSwipeBack: false` 로 경로 자체를 끊고 X 만 남긴다.
