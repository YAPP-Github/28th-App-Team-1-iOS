# Home 도메인

홈 탭. **외부 IO 가 없는 Feature 예시** — Domain(Client) 의존 없이 `.composableArchitecture` 만 쓰는 단일 Feature 모듈(`FeatureHome`). 현재 골격에서 유일한 실 Feature 다.

개편 예정 — PRD Part 6(홈)·Part 7(회원가입·계정 상태) 매핑(위젯 3종·잔여 표시·시작 게이트·A4 정지 안내)은 [home-account](../docs/work/home-account.md) 가 단일 소스. 개편되면 «외부 IO 없음» 전제가 깨진다(4종 로드).

## 흐름
`HomeFeature`(Reducer) + `HomeView`. Action 은 3분류(view/inner/delegate, [[architecture#핵심 결정 (Trade-off 기록)#D5. Reducer Action 3분류]]). 조립은 모두 AppFeature → [[app#Cross-feature Routing]].

**두 덩어리 — Reducer 2개 + 폴더 2개** (한 모듈 안). `Sources/Home/` 은 `HomeFeature` + `HomeView`(+ `HomeDefaultView`·`HomeReportView`), `Sources/StartInterview/` 은 `StartInterviewFeature` + `StartInterviewView`, 공용 배경·제스처는 `Sources/Components/`.

«홈» 3화면은 `State.phase`(GuestFeedback 패턴) — `default` / `report(ReportVariant)` 이고 report 의 변형 축은 «오랜만이에요 OO님!» 인사말 표시 여부(`returning`/`recent`) 하나다. 「면접 시작」 3화면(처음/동일 정보/이용권 소진)은 phase 가 아니라 `@Presents var startInterview` 로 **cover present** — 홈 탭엔 NavigationStack 이 없어 push 경로가 없다(`.claude/design/component/navigation.md` «부착 — push vs present»). `HomeDuringInterview` 는 MVP 제외로 삭제했다(커밋 `c3e14ee` 에 남음).

phase 를 정하는 홈 진입 로드(잔여·기록·포폴)는 미배선(서버 협의 대기) — phase 는 서버 판정의 표시일 뿐, 진실은 탭 시점 게이트 재검증([home-account](../docs/work/home-account.md) §3·§5). 응답 자리는 `inner(.reportsLoaded([Report]))` 하나가 잡아 뒀다(목록·phase 를 함께 갱신, 호출부는 TODO).

**표시 데이터는 전부 State 소유** — 뷰에 하드코딩·`@State` 를 두지 않는다. `userName`(인사말) · `reports: IdentifiedArrayOf<Report>`(위젯② 목록, 개수는 `reports.count` 파생 — 따로 들지 않는다) · `expandedReportID`(펼친 행 1개, 재탭이면 접힘). `Report` 는 `HomeFeature` 안의 표시 모델이고 `DomainInterviewReport` 이관은 목록 계약 확정 후다(TODO — 지금 `.domain(interface:)` 를 붙이면 «외부 IO 없음» 전제가 먼저 깨진다). 면접 시작 카드 값(`remainingChances`·`portfolio`)은 `StartInterviewFeature.State` 소유, 표기 포맷(«3.2mb»)은 뷰 몫.

「면접 시작」 진입은 두 경로다 — 리포트 시트 하향 드래그 + 스크롤 안내 문구 탭, 둘 다 `view(.userTappedStartInterview)`. 임계값·연출은 모션 시안 없이 구현자가 잡았다(`Sources/Components/HomeStartInterviewGesture.swift`, TODO). 로고 내비바는 두 phase 뷰가 같은 바라 `HomeView` 가 한 번만 붙인다(프로필 탭 → `view(.userTappedProfile)`).

홈 밖으로 나가는 4건은 delegate — `profileRequested`(마이페이지) · `reportDetailRequested(id:)`(리포트 상세) · `interviewStartRequested`·`interviewInfoEditRequested`(StartInterview 의 `startRequested`·`editInfoRequested` 를 올린 것). AppFeature 가 네 케이스를 명시로 받되 아직 `.none` + TODO 다 — 막힌 지점이 경계 한 곳에 모인다. 펼침 토글(`userTappedReportRow`)은 홈 내부 상태라 delegate 가 아니다.

dev 계 임시 버튼 2개(HomeDefaultView 소속)는 `showsOnboardingEntry`·`showsDebugLogout` 플래그로 게이팅 — `delegate(.onboardingRequested)`(온보딩 진입)·`delegate(.logoutRequested)`(세션·토큰·draft 전체 삭제).

## 주의사항
확장할 때 따라야 할 규칙.
- Feature 는 Interface 를 두지 않는 **단일 모듈**이다(D3). Reducer/View 는 `Sources/` 에. → DocC `FeatureInterface`
- 새 외부 IO 가 필요해지면 Domain 모듈을 먼저 만들고(`Domain{Name}`) `.domain(interface:)` 만 의존한다. `liveValue` 는 App/Example 이 link.
- 다른 Feature 로 전환이 생기면 직접 import 하지 말고 `delegate` → AppFeature. → [[app#Cross-feature Routing]]
