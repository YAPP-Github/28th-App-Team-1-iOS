# MyPage 도메인

마이페이지(Part5). 프로필·계정, 포트폴리오 한 개, 지난 면접 레포트 목록을 한 화면에 모은다. 지금은 **서버 연동 전**이라 `@Dependency` 없이 State 초기값(목데이터)만으로 서고, 화면 밖으로 나가는 동선은 전부 `delegate` 로만 올린다.

## 흐름
`MyPageFeature`(Reducer) + `MyPageView` + `MyPageModalCard`(모달 카드 층). Action 3분류 — [[architecture#핵심 결정 (Trade-off 기록)#D5. Reducer Action 3분류]]. 도메인 내부 화면 전환은 없다(단일 스크롤 화면 + 모달).

세 덩어리로 읽는다: ① 프로필·계정 카드 ② «내 포트폴리오» ③ «내 면접 레포트» 목록. ②·③ 만 상태를 갖는다 — 포트폴리오는 `Portfolio` enum(empty·uploading·uploaded·registered·failed) 하나가 판 생김새를 통째로 바꾸고, 레포트는 `expandedReportID` 로 한 줄만 펼친다.

## 포트폴리오 한 달 한 번 규칙
포트폴리오는 **한 달에 한 번만** 교체·삭제할 수 있고, 지워도 지난 레포트는 남는다. 이 규칙이 화면에서 세 곳에 나타난다 — 등록 상태의 회색 안내줄, 삭제/교체를 누를 때 뜨는 확인 모달, 기회가 0 이거나 면접이 진행 중일 때의 «할 수 없어요» 모달.

모달 5종은 `Modal` enum 하나로 닫아 동시 표출을 타입으로 막는다(`.hilitModal(item:)` 규칙). 삭제 불가 두 판은 안내줄 유무만 다르므로 `deleteBlocked(remaining: Int?)` 의 nil 로 접었다.

## 주의사항
확장할 때 따라야 할 규칙.
- Feature 는 Interface 를 두지 않는 **단일 모듈**이다(D3). Reducer/View 는 `Sources/` 에. → DocC `FeatureInterface`
- 연동 시 `DomainUser`·`DomainPortfolio`·`DomainInterviewReport` 의 **Interface 만** 의존한다. 추가되는 것은 ① Client 주입 ② `onAppear` 의 fetch effect ③ `Inner` 응답 케이스뿐이고, `View`·`Delegate` 계약은 그대로 둔다.
- 화면 밖으로 나가는 다섯 동선(레포트 열기·지인 피드백·로그아웃·회원탈퇴·파일 선택기)은 전부 `delegate` 다. 직접 import 금지 — 조립은 AppFeature. → [[app#Cross-feature Routing]]
- 시안의 모달 버튼 라벨이 «버튼1 / 버튼2» 플레이스홀더라 카피가 임시다. 확정되면 `MyPageModalCard` 만 고친다.
