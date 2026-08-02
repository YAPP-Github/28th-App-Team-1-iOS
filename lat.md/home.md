# Home 도메인

홈 탭. 단일 Feature 모듈(`FeatureHome`) — 진입 로드가 붙으면서 `.domain(interface: .portfolio)`·`.domain(interface: .user)` 를 의존한다(«외부 IO 없는 Feature 예시» 였던 전제는 2026-08-02 깨졌다).

개편 진행 중 — PRD Part 6(홈)·Part 7(회원가입·계정 상태) 매핑(위젯 3종·잔여 표시·시작 게이트·A4 정지 안내)은 [home-account](../docs/work/home-account.md) 가 단일 소스.

## 흐름
`HomeFeature`(Reducer) + `HomeView`. Action 은 3분류(view/inner/delegate, [[architecture#핵심 결정 (Trade-off 기록)#D5. Reducer Action 3분류]]). 조립은 모두 AppFeature → [[app#Cross-feature Routing]].

**두 덩어리 — Reducer 2개 + 폴더 2개** (한 모듈 안). `Sources/Home/` 은 `HomeFeature` + `HomeView`(+ `HomeDefaultView`·`HomeReportView`), `Sources/StartInterview/` 은 `StartInterviewFeature` + `StartInterviewView`, 공용 배경·드래그 규칙은 `Sources/Components/`.

«홈» 3화면은 `State.phase`(GuestFeedback 패턴) — `default` / `report(ReportVariant)` 이고 report 의 변형 축은 «오랜만이에요 OO님!» 인사말 표시 여부(`returning`/`recent`) 하나다. 홈 탭 자체는 AppView 가 NavigationStack 으로 감싼다(로고 내비바가 시스템 바 기반이라 스택 밖에선 조용히 안 그려짐 — `.claude/design/component/navigation.md` «부착 — push vs present»). `HomeDuringInterview` 는 MVP 제외로 삭제했다(커밋 `c3e14ee` 에 남음).

## 시트 자리
phase 와 **직교하는 두 번째 축** — 리포트 시트가 앉는 자리 `State.sheetDetent`(`startInterview` / `report` 기본 / `expanded`). 한 씬에 그린 배경 · 면접 시작 · (인사말 + 시트) 세 겹이 쌓인다. 기본 ↔ 확장은 시트 **높이**가 움직이고, 기본 밑으로는 높이를 줄이지 않고 판을 **통째로 offset** 으로 밀어 내린다(`HomeSheetDrag.dismissOffset`) — 높이를 줄이면 내용이 밑에서부터 잘려 나가 바텀시트가 미끄러져 사라지는 모양이 안 된다.

「면접 시작」 3화면(처음/동일 정보/이용권 소진)이 **cover present 가 아닌 이유**: 시트를 끌어 내리는 동안 뒤에서 드러나야 하고, 손을 놓기 전까진 되돌릴 수 있어야 한다(사용자 요구 2026-08-01 — Airbnb 지도/목록 스냅 참조). 그래서 `StartInterviewFeature.State` 는 `@Presents` 옵셔널이 아니라 **늘 붙어 있고**(`Scope`), 보이는 정도는 시트 높이가 정한다. `StartInterviewView` 도 화면이 아니라 배경·내비바 없는 **한 겹**이다.

치수·임계값·착지 판정은 `Sources/Components/HomeSheetDrag.swift` 한 곳 — 60pt 를 못 넘기면 원래 자리가 아니라 **기본 자리**로 돌아간다(사용자 결정). 드래그 이동량은 뷰 `@State`(프레임마다 스토어를 때리지 않으려고), 확정된 자리만 `view(.userSettledSheet(_:))` 로 리듀서에 올린다. 홈에 다시 들어오면 `onAppear` 가 기본 자리로 되돌린다. 손잡이는 그래버·헤더에만 — 목록은 `ScrollView` 라 같은 축의 드래그가 겹친다. `default` phase 엔 펼칠 목록이 없어 `expanded` 를 막는다.

**높이 우선순위는 그린 영역이 먼저** — 기본 자리 시트는 `min(481, available - greenMinHeight)` 라 시안(812)보다 짧은 기기에서 시트가 줄고 인사말은 안 잘린다. 그래서 `HomeDefaultView` 는 두 겹을 `VStack` 이 아니라 **ZStack** 으로 쌓는다(세로로 나눠 담으면 고정 높이 시트가 먼저 먹어 그린 영역이 눌린다). 내려갈 땐 판 높이가 고정이라(offset 만 움직임) 시트 안 내용은 판과 1:1 로 같이 움직인다 — 빈 상태 중앙 정렬도 판 프레임 기준 그대로면 된다.

자리에 따라 내비바가 로고 ↔ X 로 갈리는데 **모디파이어 분기가 아니라 값**(`HilitNavigationBar.Kind`)으로 갈아끼운다 — 분기하면 SwiftUI 가 씬을 새로 만들어 드래그가 끊긴다. 면접 시작 자리에선 탭 줄도 숨긴다(`.toolbar(.hidden, for: .tabBar)` — 시안에 없어서).

「면접 시작」 진입은 두 경로다 — 시트를 끌어 내리기(`view(.userSettledSheet(.startInterview))`) + 스크롤 안내 문구 탭(`view(.userTappedStartInterview)` — 끌지 않는 지름길). 되돌리기는 내비바 X 와 소진 시안의 «홈으로» CTA 둘 다 기본 자리로 보낸다. 내비바는 두 phase 뷰가 같은 바라 `HomeView` 가 한 번만 붙인다(프로필 탭 → `view(.userTappedProfile)`).

홈 밖으로 나가는 4건은 delegate — `profileRequested`(마이페이지) · `reportDetailRequested(id:)`(리포트 상세) · `interviewStartRequested`·`interviewInfoEditRequested`(StartInterview 의 `startRequested`·`editInfoRequested` 를 올린 것). AppFeature 가 네 케이스를 명시로 받되 아직 `.none` + TODO 다 — 막힌 지점이 경계 한 곳에 모인다. 펼침 토글(`userTappedReportRow`)은 홈 내부 상태라 delegate 가 아니다.

dev 계 임시 버튼 2개(HomeDefaultView 소속)는 `showsOnboardingEntry`·`showsDebugLogout` 플래그로 게이팅 — `delegate(.onboardingRequested)`(온보딩 진입)·`delegate(.logoutRequested)`(세션·토큰·draft 전체 삭제).

## 진입 로드
`view(.onAppear)` 가 **매 진입** 프로필·포폴을 재조회한다(첫 진입만이 아니다) — 포폴은 온보딩 S2·마이페이지가, 잔여는 면접이 바꾸므로 캐시하면 무효화 신호를 AppFeature 로 돌려야 하고(Feature→Feature 금지) 1건짜리 GET 두 번보다 비싸다. 진실은 서버다([home-account](../docs/work/home-account.md) §3·§6).

두 호출은 `async let` 로 동시에 나가고 결과는 `inner(.entryLoaded(profile:portfolios:))` **한 케이스**로 돌아온다 — 묶음 API(미결 6-1)로 바뀌어도 갈아끼울 자리가 하나다. 각각 `try?` 라 **부분 실패 허용**(포폴이 죽어도 인사말·잔여는 그린다), 실패한 쪽은 nil 이라 직전 값을 지우지 않는다. `cancellable(cancelInFlight:)` 로 탭을 빠르게 오갈 때의 응답 역전을 막는다. 값은 덮어쓰기만 한다 — 재진입마다 비우면 깜빡인다.

로드값 → 표시 매핑은 `HomeFeature` 의 두 헬퍼가 전담한다. `reusablePortfolio` 는 **READY 만** 고르고(PROCESSING 을 걸면 시작 시점에 게이트가 뒤집는다 — 폴링 승격은 TODO), `startVariant` 는 잔여 0 을 최우선(`exhausted`)으로 포폴 유무를 갈라 시안 3종을 정한다 — **잔여 nil(프로필 실패·응답 전)은 0 이 아니다**: 모른다고 소진 시안을 띄우면 시작 경로가 [홈으로] 하나로 막힌다. 나머지 2종(기록 리스트 → `inner(.reportsLoaded([Report]))` · held 세션)은 계약 대기라 미배선 — 응답 자리만 잡혀 있다. phase 는 서버 판정의 표시일 뿐, 진실은 탭 시점 게이트 재검증이다.

**표시 데이터는 전부 State 소유** — 뷰에 하드코딩·`@State` 를 두지 않는다(예외는 진행 중 드래그 이동량 하나 — «시트 자리» 참조). `userName`(인사말) · `reports: IdentifiedArrayOf<Report>`(위젯② 목록, 개수는 `reports.count` 파생 — 따로 들지 않는다) · `expandedReportID`(펼친 행 1개, 재탭이면 접힘). `Report` 는 `HomeFeature` 안의 표시 모델이고 `DomainInterviewReport` 이관은 목록 계약 확정 후다(TODO). 면접 시작 카드 값(`userName`·`remainingChances`·`portfolio`)은 `StartInterviewFeature.State` 소유, 표기 포맷(«3.2mb»)은 뷰 몫이고 잔여·날짜·용량은 서버가 안 줄 수 있어 옵셔널이다(없는 조각만 뺀다 — 가짜 «0회»·«1970.01.01» 을 만들지 않는다).

**사람 이름을 기본값에 박지 않는다** — `userName` 기본값은 빈 문자열이고 비어 있는 동안 뷰가 이름 줄을 뺀다(«오랜만이에요!»). 시안 값(«재원»)을 기본값에 두면 프로필 응답이 늦을 때 모든 사용자가 남의 이름을 읽는다. 같은 이유로 `StartInterviewFeature.State` 기본값도 전부 중립(0회·포폴 없음)이고, 시안대로 보고 싶은 프리뷰가 픽스처를 명시로 넘긴다.

## 주의사항
확장할 때 따라야 할 규칙.
- Feature 는 Interface 를 두지 않는 **단일 모듈**이다(D3). Reducer/View 는 `Sources/` 에. → DocC `FeatureInterface`
- 새 외부 IO 가 필요해지면 Domain 모듈을 먼저 만들고(`Domain{Name}`) `.domain(interface:)` 만 의존한다. `liveValue` 는 App/Example 이 link.
- 다른 Feature 로 전환이 생기면 직접 import 하지 말고 `delegate` → AppFeature. → [[app#Cross-feature Routing]]
