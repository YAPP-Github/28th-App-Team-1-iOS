# Home 도메인

홈 탭. **외부 IO 가 없는 Feature 예시** — Domain(Client) 의존 없이 `.composableArchitecture` 만 쓰는 단일 Feature 모듈(`FeatureHome`). 현재 골격에서 유일한 실 Feature 다.

개편 예정 — PRD Part 6(홈)·Part 7(회원가입·계정 상태) 매핑(위젯 3종·잔여 표시·시작 게이트·A4 정지 안내)은 [home-account](../docs/work/home-account.md) 가 단일 소스. 개편되면 «외부 IO 없음» 전제가 깨진다(4종 로드).

## 흐름
`HomeFeature`(Reducer) + `HomeView`. Action 은 3분류(view/inner/delegate, [[architecture#핵심 결정 (Trade-off 기록)#D5. Reducer Action 3분류]]). 조립은 모두 AppFeature → [[app#Cross-feature Routing]].

**두 덩어리 — Reducer 2개 + 폴더 2개** (한 모듈 안). `Sources/Home/` 은 `HomeFeature` + `HomeView`(+ `HomeDefaultView`·`HomeReportView`), `Sources/StartInterview/` 은 `StartInterviewFeature` + `StartInterviewView`, 공용 배경은 `Sources/Components/`.

«홈» 3화면은 `State.phase`(GuestFeedback 패턴) — `default` / `report(ReportVariant)` 이고 report 의 변형 축은 «오랜만이에요 OO님!» 인사말 표시 여부(`returning`/`recent`) 하나다. 「면접 시작」 3화면(처음/동일 정보/이용권 소진)은 phase 가 아니라 `@Presents var startInterview` 로 **cover present** — 홈 탭엔 NavigationStack 이 없어 push 경로가 없다(`.claude/design/component/navigation.md` «부착 — push vs present»). `HomeDuringInterview` 는 MVP 제외로 삭제했다(커밋 `c3e14ee` 에 남음).

phase 를 정하는 홈 진입 로드(잔여·기록·포폴)는 미배선(서버 협의 대기) — phase 는 서버 판정의 표시일 뿐, 진실은 탭 시점 게이트 재검증([home-account](../docs/work/home-account.md) §3·§5). StartInterview 의 `startRequested`·`editInfoRequested` 는 cross-feature 라 AppFeature 배선과 함께 `HomeFeature.Action.Delegate` 케이스를 신설해야 한다(현재 TODO).

dev 계 임시 버튼 2개(HomeDefaultView 소속)는 `showsOnboardingEntry`·`showsDebugLogout` 플래그로 게이팅 — `delegate(.onboardingRequested)`(온보딩 진입)·`delegate(.logoutRequested)`(세션·토큰·draft 전체 삭제).

## 주의사항
확장할 때 따라야 할 규칙.
- Feature 는 Interface 를 두지 않는 **단일 모듈**이다(D3). Reducer/View 는 `Sources/` 에. → DocC `FeatureInterface`
- 새 외부 IO 가 필요해지면 Domain 모듈을 먼저 만들고(`Domain{Name}`) `.domain(interface:)` 만 의존한다. `liveValue` 는 App/Example 이 link.
- 다른 Feature 로 전환이 생기면 직접 import 하지 말고 `delegate` → AppFeature. → [[app#Cross-feature Routing]]
