# 온보딩 도메인 — 신규 사용자 셋업 위저드 (FeatureOnboarding)

가입 직후 프로필·면접 재료를 수집하는 6화면 위저드 (Figma «STEP N_…»). 코디네이터가 스텝을 조율하고, 각 화면은 독립 리듀서+뷰(Onboarding<StepName>)로 분리된다. 수집 스텝은 5개(프로그레스 바 5칸), 분석 화면은 프로그레스 밖의 종결 화면이다.

이 위저드가 「[PRD] AI 면접 Part 1 — 면접 전 입력 & 포트폴리오 등록」 v3 의 S0~S4 구현체 — PRD↔구현 매핑·잔여 개발 포인트는 [ai-interview](../docs/work/ai-interview.md) §5 가 단일 소스. PRD v3 확정 골자: 재시도·멱등성 전면 제외(실패=status 표시 후 재업로드), 비동기+폴링 확정, 개별 저장 API 없이 세션 생성이 S0~S3 일괄 수집, 직군 6종 화이트리스트, 태블릿 제외.

## 코디네이터

OnboardingFeature 가 위저드 루트. STEP 1(직군 선택)을 NavigationStack 루트로 두고, 이후 스텝은 `path`(StackState)로 push 한다. 각 스텝의 delegate 만 매칭해 [[onboarding#수집 데이터]]를 누적하고 다음 스텝으로 전환한다 — 조립은 코디네이터에서만.

순서: 직군 → 연차 → JD 링크 → 포트폴리오 → 집중 프로젝트 → 분석. 뒤로가기(backRequested)는 popLast, 닫기(closeRequested)는 delegate(.dismiss), 분석 완료(completed)는 delegate(.finished) — dismiss/finished 구분은 AppFeature 가 이탈/완료를 다르게 처리하기 위함. 총 스텝 수는 `OnboardingFeature.totalSteps = 5` 단일 소스. @Reducer enum 이 만드는 Path.State 는 Equatable 을 자동 채택하지 않아 명시 채택한다. → [[app]]

## 직군 선택

STEP 1 (필수). 진입 시 JobClient.jobs 로 선택지를 로드해 칩으로 나열하고, 하나를 고르면 '계속하기'가 활성화된다. 완료 시 선택 직군의 jobRole(서버 enum, 예 "BACKEND")을 delegate 로 올린다. 이 스텝만 하단 CTA 가 단일 버튼이다(첫 스텝 — 이전 없음).

- 실패 UX 미정: jobsLoadFailed 는 로딩 해제만 (TODO).

## 연차 입력

STEP 2 (필수). 문장형 휠 피커 «내 경력은 [휠] 이다.» — 정수 연차 0~10년(`CareerOption { years: Int }`, 10="10년 이상", 라벨 신입/N년차/10년 이상). 휠은 native Picker 가 아니라 iOS 17 ScrollView(viewAligned + scrollPosition) 커스텀. 항상 값이 있어 CTA 상시 활성.

delegate 는 `continueRequested(careerYears: Int)` — 페이로드(`OnboardingData.careerYears`)·세션 입력(`InterviewConfig.careerYears`)에 정수 그대로 직결한다(잠정 매핑 없음). 레벨(주니어/미들/시니어)은 서버가 0-2/3-7/8+ 파생 — 클라 미관여.

이 스텝부터 하단 CTA 가 «이전으로 | 계속하기» 2분할 바(가운데 dsGray700 구분선)이고, 내비바에는 닫기(X)만 있다 — 뒤로가기는 하단 바 담당 (STEP 2~5 공통 골격).

## JD 링크

STEP 3 (선택 — 스킵 가능). 탭 «JD 붙여넣기 / 직접 입력하기»는 화면 전환이 아니라 State 의 InputMode. 링크 검증은 **1초 디바운스 → 클라이언트 형식 검사 → 통과분만 서버(JDClient.validate)** 2단. 결과는 delegate(.continueRequested(JDSubmission?)) — .link/.text/nil(스킵).

형식 검사는 http/https 스킴+호스트(`isValidLinkFormat`) — 불일치는 서버 왕복 없이 즉시 에러 문구. 로딩/에러/성공은 LinkValidation 하위 상태로 표현하고 필드 하단 4px 스트립 색으로 구분한다. 키패드 밖 터치 시 내림(`dismissesKeyboardOnTap` — SharedDS 공통).

- 성공 후엔 직접입력 탭 비활성, 검증 중 계속하기 무시. 스킵 시 입력이 있어도 검증·저장 없이 통과(jd=nil).
- 직접입력 **200~3,000자** 검증 ✅ — 유효 길이만 계속하기 활성(무효 시 카운터·red 보더·안내 문구, 초과는 클램프 안 함). 빈 입력은 스킵.
- PRD 잔여(TODO): 카피 3곳(헬퍼·에러 fallback) · 링크 본문 <200자 = `CONTENT_TOO_SHORT` 문구 · **링크 검증 1일 5회 제한** 초과 에러. S1 은 캐싱만 — 분석은 세션 생성 시.

## 포트폴리오 업로드

STEP 4 (필수). PDF 1개(최대 20Mb)를 fileImporter 로 받아 PortfolioClient.register → PROCESSING 이면 3초 간격 status 폴링 → READY/FAILED. idle/uploading/failed/uploaded 를 UploadState 하위 상태로 표현, uploaded 일 때만 계속하기 활성. 파일 제거(X)는 폴링 취소 + 서버 delete.

- 완료 행 디자인 미확인(진행 스트립만 뺀 근사) · 진행률 이벤트 없어 스트립은 고정 비율 · 폴링 상한 없음 (전부 TODO).
- PRD 검증 분담(클라 선검증 = UX 용 빠른 차단, 최종 판정은 서버 실측): PDF 타입·20MB·**페이지 ≤30**(PDFKit pageCount)·**암호 PDF**(PDFDocument.isEncrypted) 선검증 ✅ — PortfolioFileReader 가 data+pageCount+isEncrypted 반환, register 전 차단. 페이지 수는 PortfolioUpload.pageCount 로 서버에 전달. 글자 수 ≥30 은 서버 전용(Tika) → FAILED_FILE 문구만.
- **1개 제한**: 재등록 시 `PORTFOLIO_ALREADY_EXISTS` → "기존 삭제 후 재업로드" dialog(자동 교체 금지). **폴링 상한** 초과 시 FAILED_SYSTEM 취급 문구(초기값 tentative).

## 집중 프로젝트

STEP 5 (선택 — 마지막 수집 스텝, 프로그레스 5/5). 300자 자유 입력 + «나중에 등록해도 괜찮아요!» 툴팁. 빈 입력·공백만이면 nil(건너뜀)로 올린다. 필드는 InterviewConfig.freeText(10~300자)에 대응 — 하한 10자는 서버 위임.

상단 안내는 PRD S3 확정 문구(«입력하면 그 부분을 집중 검증해요. 건너뛰면 포트폴리오 전체에서 질문해요.») — 스킵과 모순되던 구 카피 폐기 ✅. `relevanceWarning`(옵셔널)로 연관성 실패 시 경고를 노출하고 편집(입력/클리어) 시 해제한다 — 주입은 코디네이터 [[onboarding#분석]].

## 분석

종결 화면 (프로그레스·뒤로가기 없음, 다크 풀스크린). 코디네이터가 누적 OnboardingData 를 init 으로 주입 — 서버 제출 지점(세션 생성+폴링). 체크리스트 3행은 순차 진행 — 1·2행은 가짜 타이머(1.2s), 3행만 가짜 완료 AND 세션 READY 로 체크. 잠깐 노출 후 완료 화면 → delegate(.completed). X 는 분석 중에도 이탈 가능, pop 시 effect 자동 취소.

세션 생성 연결 = PRD S3.5+S4. → [[interview#Client 계약]]
- ① OnboardingData.interviewConfig() → InterviewClient.createSession + sessionStatus 폴링(3초) ✅. `.domain(interface: .interview)` 의존 추가. PROCESSING→폴링, READY→completed(sessionId), 실패→failed 화면(재시도 없음), config 불완전→failed. onAppear 가드로 중복 시작 방지. CancelID.session 으로 pop 시 취소.
- ④ READY → delegate(.completed(sessionId)) → 코디네이터 delegate(.finished(sessionId:)) ✅. AppFeature 미배선이라 요약 질문 등 payload 확장은 배선 시.
- ② 연관성 실패 처리 ✅ — `FREETEXT_NOT_RELEVANT` 를 DomainInterview 가 `InterviewError.freeTextNotRelevant` 로 매핑, 분석이 delegate(.relevanceCheckFailed) → 코디네이터가 분석 popLast + relevanceFailureCount++.
- ③ 재입력 유도 ✅ — 4회 미만은 집중 프로젝트에 경고 문구 주입(편집 시 해제), **4회째**는 코디네이터의 `ConfirmationDialogState` 2선택지([포폴 다시 올리기→STEP4 pop] / [집중 프로젝트 없이 진행→freeText=nil 재분석]).

## 수집 데이터

OnboardingData — 위저드가 스텝을 거치며 채우는 공유 페이로드(Codable — draft 영속용). 코디네이터가 소유하고 각 스텝 delegate 결과를 누적, 분석 스텝에 통째로 주입된다.

필드: userName(주입) · jobRole · careerYears(정수) · jd(JDSubmission — .link/.text 상호 배타를 타입 보장, 스킵 nil) · portfolioId · portfolioFileName(draft 복원용) · freeText. JDSubmission 은 OnboardingData.swift 소속 — JD 스텝 delegate 가 올린 값을 코디네이터가 해체 없이 저장한다.

## 입력 draft

PRD §4.4 — S0~S3 입력을 로컬 draft 로 자동 저장해 **앱 진짜 종료(kill/크래시) 시 재입력 방지**(백그라운드 전환은 프로세스 생존이라 무관). **재개식**: 값 + 위저드 위치 복원.

`OnboardingDraftStore` seam(UserDefaults JSON — PortfolioFileReader 와 같은 로컬 IO 선상, testValue unimplemented). OnboardingData 는 Codable + portfolioFileName. 코디네이터가 각 스텝 완료마다 `persist`(data·furthestStep=path.count+1·savedAt) 저장, **세션 생성 성공 시 clear**. onAppear 는 path 빈 경우만 TTL 14일 안 draft 를 복원 — 분석(6) 제외 집중 프로젝트(5)까지 되쌓고, 직군은 목록 로드 후 preselectedJobRole 매칭, JD 는 restoring init. 잔여: 복원 시 직무 목록 대조 재검증·포폴 삭제 시 clear.

## 재진입 분기

앱 종료 후 재진입은 [[onboarding#입력 draft]] 가 값·위저드 위치를 복원해 처리한다. 🟡 잔여 refinement: 폴링 중 강제종료 시 draft 는 포폴 스텝(미완료)으로 복원되므로 PortfolioClient.list 로 status 재조회해 그새 READY 면 집중 프로젝트로 건너뛰기(draft 와 겹쳐 우선순위 낮음). 포폴 0개(삭제됨) → 다음 진입 시 S2 강제 라우팅은 AppFeature 몫 → [[app]].

## 스텝 템플릿

OnboardingPlaceholderStepFeature/View — 스텝 골격(내비바·프로그레스 바·CTA) 템플릿. 실제 스텝 6개가 모두 붙으면서 코디네이터 Path 에서는 빠졌고, 새 스텝 추가 시 복사 출발점으로만 남아 있다 (view/inner/delegate 3분류, delegate 로 continue/back/close 만 통보).

## 코디네이터 연결

**dev 전용 임시 진입**만 배선된 상태다 — Home 의 dev 버튼 신호를 AppFeature 가 받아 로그인 이후 `fullScreenCover` 로 위저드를 연다(토큰 보유). 정식 통합은 아직. → [[app]]

현재는 `OnboardingFeature.State()`(닉네임 없음)로 열고 `.finished`·`.dismiss` 는 cover 를 닫기만 한다. 정식 배선 시: 닉네임(userName) 주입, delegate(.dismiss) → 중도 이탈(draft 보존), **delegate(.finished(sessionId:)) → Part 2 면접 바로 시작**(사용자 결정 2026-07-20, InterviewSessionFeature 생기면 fullScreenCover).

코디네이터 onAppear 가 draft 복원을 트리거하므로 OnboardingView 는 루트에 onAppear 를 발신한다. Example 앱은 전체 위저드를 스텁 의존성으로 구동하며 ONBOARDING_START_STEP 환경변수로 특정 스텝부터 시작할 수 있다(draft 는 no-op 스텁). → [[app]]

PRD §3.8 부록대로 Part1↔2 경계는 세션 생성 API 계약 — .finished 는 현재 무페이로드라 세션 payload(sessionId·요약 질문) 확장 필요(서버 정합). 권한(카메라·마이크)은 iOS = 사용 시점 요청이라 온보딩이 아니라 Part 2 진입 직전.
