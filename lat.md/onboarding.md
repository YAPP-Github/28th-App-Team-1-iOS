# 온보딩 도메인 — 면접 재료 수집 위저드 (FeatureOnboarding)

가입 직후 면접 재료를 수집하는 4화면 위저드. 코디네이터가 스텝을 조율하고, 각 화면은 독립 리듀서+뷰(Onboarding<StepName>)로 분리된다. 수집 스텝은 3개(프로그레스 바 3칸), 프리로드는 프로그레스 밖의 종결 화면이다.

이 위저드가 「[PRD] AI 면접 Part 1 — 면접 전 입력 & 포트폴리오 등록」 v3 의 S1~S4 구현체 — PRD↔구현 매핑·잔여 개발 포인트는 [ai-interview](../docs/work/ai-interview.md) §5 가 단일 소스. PRD v3 확정 골자: 재시도·멱등성 전면 제외(실패=status 표시 후 재업로드), 비동기+폴링 확정, 개별 저장 API 없이 세션 생성이 S0~S3 일괄 수집, 직군 6종 화이트리스트, 태블릿 제외.

**직군·연차(구 STEP1·2)는 이 위저드에 없다** — 가입 온보딩(`FeatureAuth` — `AuthOnboardingJob`·`AuthOnboardingExperience`)으로 이관됐고 원본 화면은 삭제됐다(2026-08-02). 두 값은 세션 생성 입력에 여전히 필수라 `OnboardingFeature.State.init(userName:jobRole:careerYears:)` 으로 **주입**받아 [[onboarding#수집 데이터]]에 실린다. 주입원 배선은 미결 — [home-account](../docs/work/home-account.md) §0·§7 참조.

## 코디네이터

OnboardingFeature 가 위저드 루트. STEP 1(JD 업로드)을 NavigationStack 루트로 두고, 이후 스텝은 `path`(StackState)로 push 한다. 각 스텝의 delegate 만 매칭해 [[onboarding#수집 데이터]]를 누적하고 다음 스텝으로 전환한다 — 조립은 코디네이터에서만.

순서: JD 업로드 → 포트폴리오 → 대표 프로젝트 → 프리로드. 뒤로가기(backRequested)는 popLast, 닫기(closeRequested)는 delegate(.dismiss), 프리로드 완료(completed)는 delegate(.finished) — dismiss/finished 구분은 AppFeature 가 이탈/완료를 다르게 처리하기 위함. **루트의 «이전으로» 는 앞 스텝이 없어 dismiss 와 같은 신호로 합류한다**(어디로 돌아갈지는 부모가 정한다 — 가입 온보딩이 앞에 있다). 총 스텝 수는 `OnboardingFeature.totalSteps = 3` 단일 소스. @Reducer enum 이 만드는 Path.State 는 Equatable 을 자동 채택하지 않아 명시 채택한다. → [[app]]

## JD 업로드

STEP 1 (선택 — 스킵 가능, 위저드 루트). 탭 «링크 붙여넣기 / 직접 입력하기»는 화면 전환이 아니라 State 의 InputMode. 링크 검증은 **1초 디바운스 → 클라이언트 형식 검사 → 통과분만 서버(JDClient.validate)** 2단. 결과는 delegate(.continueRequested(JDSubmission?)) — .link/.text/nil(스킵).

형식 검사는 http/https 스킴+호스트(`isValidLinkFormat`) — 불일치는 서버 왕복 없이 즉시 에러 문구. 에러/성공은 LinkValidation 하위 상태를 필드 변형(`HilitTextField.Status`)으로 그린다. 키패드 밖 터치 시 내림(`dismissesKeyboardOnTap` — SharedDS 공통).

**`.loading` 은 화면에 안 그린다** — 전역 LoadingModal 이 `JDClient.validate` 를 덮으므로 인라인 스피너를 두면 이중 로딩이다([[auth]] 가입 플로우와 같은 방침). 상태 자체는 남아 검증 중 계속하기를 막는 게이트로 쓰인다. 필드 잠금(`.loading` 변형의 `disabled`)도 함께 사라졌는데 안전하다 — 검증 중 타이핑은 `.idle` 로 되돌리며 in-flight 를 취소한다. 200ms 켜기 지연 안에 끝난 검증은 모달조차 안 뜬다(의도 — 그 구간은 «즉시»로 읽힌다).

- 성공 후엔 직접입력 탭 비활성, 검증 중 계속하기 무시. 스킵 시 입력이 있어도 검증·저장 없이 통과(jd=nil).
- 직접입력 **200~3,000자** 검증 ✅ — 유효 길이만 계속하기 활성(무효 시 카운터·에러 표시, 초과는 클램프 안 함). 빈 입력은 스킵.
- PRD 잔여(TODO): 카피 3곳(헬퍼·에러 fallback) · 링크 본문 <200자 = `CONTENT_TOO_SHORT` 문구 · **링크 검증 1일 5회 제한** 초과 에러. S1 은 캐싱만 — 분석은 세션 생성 시.

## 스텝 공통 골격

수집 스텝 3개가 공유하는 껍데기: 상단 `DashIndicator`(3칸) · 헤더 `TitleBox`(뱃지·마커 타이틀·서브) · 하단 «이전으로 | 계속하기» 2분할 바 · 네비바 X(+선택 스텝은 trailing «건너뛰기»).

바는 DS `ButtonLarge(.bottom, tone: .dark)` 가 그린다(배경·구분선·등폭·비활성 룩 전부 DS 소유) — 화면은 라벨과 액션만 넘긴다. 엣지 스와이프백은 기본 허용 — pop 전에 되물을 게 있는 화면만 차단한다(포트폴리오 업로드 중 `!isUploading`, 프리로드 상시). 스와이프 pop 은 코디네이터에 `popFrom(id:)` 로 도착하며 `backRequested` 와 결과 동일(popLast 뿐)이라 별도 처리 없음 — back 경로에 로직을 넣게 되면 두 입구를 모두 살필 것.

네비바는 DS `.hilitNavigationBar` = **시스템 네비바**라서 [[onboarding#코디네이터]]의 NavigationStack 에 렌더를 의존한다(2026-07-31 커스텀 바 폐기). 스택을 걷어내면 전 스텝의 바가 컴파일 성공 상태로 조용히 사라지므로, 위저드를 cover 단독 화면으로 재구성할 땐 스택을 유지하거나 `.hilitPresentedNavigationBar` 로 바꿔 달 것.

## 포트폴리오 업로드

STEP 2 (필수). PDF 1개(최대 20Mb)를 fileImporter 로 받아 PortfolioClient.register → PROCESSING 이면 3초 간격 status 폴링 → READY/FAILED. idle/uploading/failed/uploaded 를 UploadState 하위 상태로 표현, uploaded 일 때만 계속하기 활성. 파일 제거(X)는 폴링 취소 + 서버 delete.

접수~폴링 구간은 **전역 로딩(LoadingModal)에서 뺀다** — 이 화면이 그동안 진행 카드(`FileUpload.progressing`)를 그리고 그 카드에 취소 X 가 달려 있어, 모달로 덮으면 카드도 취소 동선도 가려진다. 억제는 `PortfolioClient.register`·`.status` 의 liveValue 에 `GlobalLoadingSuppression.run` 으로 건다 (Feature 는 Core 를 모른다) → [[domain.map#네트워킹 인프라]]

- 진행 바는 `UploadState.phaseProgress` — register 접수 전/후 두 단계를 가리키는 **단계 마커**다(0.3 → 0.7). View 의 12초 가짜 램프는 폐기 ✅ — 실측 진행률이 없어 지어내면 실제와 어긋난다. 전이만 이징하고 폴링 구간은 정지하므로, 그 구간의 대기 신호는 상태 문구가 진다. 실제 진행률은 업로드 progress 이벤트나 서버 퍼센트가 생겨야 가능 (TODO) · 폴링 상한 없음 (TODO).
- PRD 검증 분담(클라 선검증 = UX 용 빠른 차단, 최종 판정은 서버 실측): PDF 타입·20MB·**페이지 ≤30**(PDFKit pageCount)·**암호 PDF**(PDFDocument.isEncrypted) 선검증 ✅ — PortfolioFileReader 가 data+pageCount+isEncrypted 반환, register 전 차단. 페이지 수는 PortfolioUpload.pageCount 로 서버에 전달. 글자 수 ≥30 은 서버 전용(Tika) → FAILED_FILE 문구만.
- **실패 문구는 서버 원문** (현행): 4xx 는 `PortfolioError.userMessage`(서버 message), 200 + FAILED_FILE/FAILED_SYSTEM 은 응답 `message` 를 배너에 그대로 싣고, 없을 때만 클라 폴백 문구를 쓴다. 코드별 클라 카피·PRD 문구 정책 미확정이라 임시(코드 TODO 표시).
- **X = 삭제 확인 모달**: 파일 행 X(`userTappedRemoveFile`)는 확인 모달만 띄우고(`isDeleteConfirmPresented`), 폴링 취소 + `delete` API 는 «네»(`userTappedDeleteConfirm`)에서만 나간다 — 실수 탭으로 서버 파일이 사라지지 않게. 카드는 마이페이지 삭제 모달(435:8892)과 같은 계열이고 버튼만 «아니요 / 네». 남은 삭제 횟수는 서버가 목록 응답에 안 줘서(deleteAvailable·nextDeleteAvailableAt 만) 안내줄이 «1번» 고정 — TODO.
- **2회차 이상 = 기존 포폴 확인 모달** ✅ (2026-08-03): 진입(`view(.onAppear)`)에 `PortfolioClient.list` 로 READY 를 찾으면 «기존에 있는 포트폴리오로 진행할까요?» 모달을 띄우고, «예» 가 재등록·폴링 없이 곧장 `uploaded` 로 앉힌다. **버튼이 하나인 건 고를 게 없어서다** — 포폴은 계정당 1개고 교체는 한 달 1회라 «아니요» 를 줘도 갈 곳이 없다(바꾸려면 완료 판 X → 삭제 확인 모달이 그 자리). 조회는 **빈 판 진입마다 1회** (2026-08-04 정정 — 이전 판은 «위저드 수명당 1회») — 서버 READY 는 위저드 밖에서 바뀌므로(마이페이지 업로드·삭제, PROCESSING 승격) 수명당 1회로 묶으면 두 번째 진입에서 재사용 대상을 놓치고 register 가 409 로 떨어진다. 코디네이터는 `portfolioStep(upload:)` 에서 `upload == .idle` 일 때만 `checksExisting` 을 켜고(이미 첨부된 판엔 물어볼 게 없다), 중복 호출 방지는 스텝 State 가 `onAppear` 첫 발동에 스스로 끄는 것으로 끝낸다. 첨부된 판으로 pop 복귀하는 경로엔 애초에 조회가 안 켜져서 «기존 포폴로 진행할까요?» 가 다시 뜨지 않는다. 화면에서 삭제(X → «네») 해 빈 판이 돼도 재조회는 하지 않는다 — 방금 지운 걸 다시 쓰라고 묻는 꼴이라. 실패·부재는 조용히 넘긴다(평소의 빈 판 = 1회차 흐름). 판정 키의 근거는 [home-account](../docs/work/home-account.md) §3 «회차 분기 판정 키».
- **1개 제한 + 409 자동 복구 — 미구현 🔴** (2026-08-02 코드 대조로 정정. 이전 판이 ✅ 로 적어 뒀으나 리듀서엔 없다): register 가 `PORTFOLIO_ALREADY_EXISTS`(409)를 주면 지금은 서버 문구 배너와 함께 failed 로 떨어진다. 설계 의도는 `PortfolioClient.list().first`(계정당 1개라 first 가 곧 그 포폴)로 서버의 기존 포폴을 회수하는 것 — READY 면 uploaded 확정, PROCESSING 이면 폴링 이어받기, FAILED/부재면 삭제 후 재업로드 유도. draft 를 잃었지만(로그아웃·재설치·TTL 만료) 서버 포폴은 남은 경우를 투명 처리하려는 것이고, 원칙은 draft=재개 힌트·서버=진실([[onboarding#프리로드]] JD 복구와 같은 계) — 그쪽은 실제로 구현돼 있다. **폴링 상한**도 미구현.

## 대표 프로젝트

STEP 3 (선택 — 마지막 수집 스텝, 프로그레스 3/3). 300자 자유 입력(DS `HilitTextEditor` — 카운터·클램프를 컴포넌트가 소유) + «나중에 등록해도 괜찮아요!» 툴팁(진입 후 3초 뒤 자동 소멸, onAppear 타이머). 빈 입력·공백만이면 nil(건너뜀)로 올린다.

필드는 InterviewConfig.freeText(10~300자)에 대응. 상한 300자는 입력 클램프, 하한 10자는 continue 로컬 선검증(PRD §7 «클라 선검증=UX 차단, 최종 판정=서버») — 입력이 있고 <10자면 차단+경고, 최종 판정(연관성 등)은 서버. **네비바 «건너뛰기»는 선검증을 타지 않는다** — 입력이 있어도 버리고 nil 로 올린다(빈 입력 경로와 합류).

`inputWarning`(옵셔널) 슬롯 1개로 하한 미달(로컬) 또는 연관성 실패(코디네이터 주입 [[onboarding#프리로드]]) 경고를 노출하고 편집 시 해제한다.

## 프리로드

종결 화면 (프로그레스·뒤로가기 없음, 다크 풀스크린). 코디네이터가 누적 OnboardingData 를 init 으로 주입 — 서버 제출 지점(세션 생성+폴링). 체크리스트 3행은 순차 진행 — 1·2행은 가짜 타이머(1.2s), 3행만 가짜 완료 AND 세션 READY 로 체크. 잠깐 노출 후 완료 화면 → delegate(.completed). X 는 진행 중에도 이탈 가능, pop 시 effect 자동 취소.

이 화면이 곧 대기 표시라 **전역 로딩을 얹지 않는다** — `InterviewClient.createSession`·`.sessionStatus` liveValue 에 `GlobalLoadingSuppression.run` 을 건다. AppView 가 Splash 계열 루트를 제외하는 것과 같은 이유(브랜드 대기 화면을 로딩 판이 가린다) → [[domain.map#네트워킹 인프라]] · [[app#Splash 세션 복구]]

세션 생성 연결 = PRD S3.5+S4. → [[interview#Client 계약]]
- ① OnboardingData.interviewConfig() → InterviewClient.createSession + sessionStatus 폴링(3초) ✅. `.domain(interface: .interview)` 의존. PROCESSING→폴링, READY→completed(sessionId), 실패→failed 화면(재시도 없음), config 불완전→failed. onAppear 가드로 중복 시작 방지. CancelID.session 으로 pop 시 취소. createSession effect 는 `startSession(config:)` 로 추출해 최초 시도와 JD 재검증 후 재시도가 공유. **config 불완전은 이제 주입 실패도 포함한다** — 직군·연차가 nil 인 채 위저드가 열리면 여기서 failed 로 떨어진다.
- ①-JD 검증 만료 자동 복구 ✅ — 서버 JD 검증 캐시는 단명이라 오래된 draft 로 재개하면 createSession 이 `JD_NOT_VALIDATED` 로 거부된다(draft 는 jd 를 영구 유효로 착각). 이때 죽지 않고 저장된 `.link` 를 `JDClient.validate` 로 **1회**(`didRetryJDValidation` 가드) 재검증→valid 면 세션 생성 재시도, invalid/링크 아님이면 failed. 원칙: draft=재개 힌트·서버=진실, 서버 부작용 값은 직전에 서버와 화해. `.domain(interface: .jd)` 의존. → [[api#Interview]]
- ④ READY → delegate(.completed(sessionId)) → 코디네이터 delegate(.finished(sessionId:)) ✅. AppFeature 미배선이라 요약 질문 등 payload 확장은 배선 시.
- ② 연관성 실패 처리 ✅ — `FREETEXT_NOT_RELEVANT` 를 DomainInterview 가 `InterviewError.freeTextNotRelevant` 로 매핑, 프리로드가 delegate(.relevanceCheckFailed) → 코디네이터가 프리로드 popLast + relevanceFailureCount++.
- ③ 재입력 유도 ✅ — 4회 미만은 대표 프로젝트에 경고 문구 주입(편집 시 해제), **4회째**는 코디네이터의 `ConfirmationDialogState` 2선택지([포폴 다시 올리기→STEP2 pop] / [대표 프로젝트 없이 진행→freeText=nil 재분석]).

## 수집 데이터

OnboardingData — 위저드가 스텝을 거치며 채우는 공유 페이로드(Codable — draft 영속용). 코디네이터가 소유하고 각 스텝 delegate 결과를 누적, 프리로드 스텝에 통째로 주입된다.

필드: userName·jobRole·careerYears(셋 다 주입 — 화면 없음) · jd(JDSubmission — .link/.text 상호 배타를 타입 보장, 스킵 nil) · portfolioId · portfolioFileName(draft 복원용) · freeText. JDSubmission 은 OnboardingData.swift 소속 — JD 스텝 delegate 가 올린 값을 코디네이터가 해체 없이 저장한다.

## 입력 draft

PRD §4.4 — 입력을 로컬 draft 로 자동 저장해 **앱 진짜 종료(kill/크래시) 시 재입력 방지**(백그라운드 전환은 프로세스 생존이라 무관). **재개식**: 값 + 위저드 위치 복원.

`OnboardingDraftStore` seam(UserDefaults JSON — PortfolioFileReader 와 같은 로컬 IO 선상, testValue unimplemented). OnboardingData 는 Codable + portfolioFileName. 코디네이터가 각 스텝 완료마다 `persist`(data·furthestStep=path.count+1·savedAt) 저장, 폐기는 위저드가 아니라 **인터뷰 세션 완료 시 AppFeature 가 clear**(세션 생성 시점에 지우면 면접 도중 킬·이탈에 값이 사라지고 홈의 재사용·[수정하기] 복원도 끊긴다 → [[app]]). onAppear 는 **위저드 수명당 1회**(`didAttemptRestore` 가드) TTL 14일 안 draft 를 복원 — 프리로드(4) 제외 대표 프로젝트(3)까지 되쌓고, JD 는 루트라 `restoring:` init 으로 되살린다. 1회 가드가 필수인 이유: 루트 onAppear 는 뒤로가기로 루트 복귀 때마다 재발동하는데, 가드가 `path.isEmpty` 뿐이면 pop 으로 스택이 빈 순간 draft 를 다시 되쌓아 화면이 앞으로 튄다. 잔여: 포폴 삭제 시 clear.

## 재진입 분기

앱 종료 후 재진입은 [[onboarding#입력 draft]] 가 값·위저드 위치를 복원해 처리한다. draft 에 portfolioId 가 안 들어간 채(업로드는 끝났지만 «계속하기» 전에 죽음) 재진입해도 STEP2 진입 조회가 그 포폴을 찾아 확인 모달로 되살린다 — 대표 프로젝트로 자동 건너뛰지는 않는다. 포폴 0개(삭제됨) → 다음 진입 시 포폴 스텝 강제 라우팅은 AppFeature 몫 → [[app]].

## 스텝 템플릿

OnboardingPlaceholderStepFeature/View — 스텝 골격(네비바·프로그레스 바·CTA) 템플릿. 실제 스텝이 모두 붙으면서 코디네이터 Path 에서는 빠졌고, 새 스텝 추가 시 복사 출발점으로만 남아 있다 (view/inner/delegate 3분류, delegate 로 continue/back/close 만 통보).

## 코디네이터 연결

홈 「면접 시작」의 [시작하기]·[수정하기] 신호를 AppFeature 가 받아 `fullScreenCover` 로 위저드를 연다 — 홈 탭 위에서만 열리므로 **로그인 이후**라 토큰을 보유한다(온보딩 API 는 인증 필요). dev 전용 임시 진입 버튼은 이 정식 경로가 생기며 제거됐다(2026-08-03). → [[app]]

현재는 `OnboardingFeature.State()`(닉네임·직군·연차 없음)로 열고 `.finished`·`.dismiss` 는 cover 를 닫기만 한다. 정식 배선 시: **닉네임·직군·연차를 사용자 프로필에서 주입**(직군·연차가 nil 이면 프리로드가 세션 생성에 실패한다 — 배선의 필수 조건), delegate(.dismiss) → 중도 이탈(draft 보존), **delegate(.finished(sessionId:)) → Part 2 면접 바로 시작**(사용자 결정 2026-07-20, InterviewSessionFeature 생기면 fullScreenCover).

코디네이터 onAppear 가 draft 복원을 트리거하므로 OnboardingView 는 루트에 onAppear 를 발신한다. 단 루트 onAppear 는 SwiftUI 특성상 뒤로가기로 루트에 되돌아올 때마다 재발동하므로, 복원은 `didAttemptRestore` 로 1회만 수행한다(재복원=화면 튐 방지). Example 앱은 전체 위저드를 스텁 의존성으로 구동하며 ONBOARDING_START_STEP 환경변수로 특정 스텝부터 시작할 수 있다(draft 는 no-op 스텁). → [[app]]

PRD §3.8 부록대로 Part1↔2 경계는 세션 생성 API 계약 — .finished 는 sessionId 만 실어 올리므로 요약 질문 등 payload 확장이 필요하다(서버 정합). 권한(카메라·마이크)은 iOS = 사용 시점 요청이라 온보딩이 아니라 Part 2 진입 직전.
