# 온보딩 도메인 — 신규 사용자 셋업 위저드 (FeatureOnboarding)

가입 직후 프로필·면접 재료를 수집하는 6화면 위저드 (Figma «STEP N_…»). 코디네이터가 스텝을 조율하고, 각 화면은 독립 리듀서+뷰(Onboarding<StepName>)로 분리된다. 수집 스텝은 5개(프로그레스 바 5칸), 분석 화면은 프로그레스 밖의 종결 화면이다.

## 코디네이터

OnboardingFeature 가 위저드 루트. STEP 1(직군 선택)을 NavigationStack 루트로 두고, 이후 스텝은 `path`(StackState)로 push 한다. 각 스텝의 delegate 만 매칭해 [[onboarding#수집 데이터]]를 누적하고 다음 스텝으로 전환한다 — 조립은 코디네이터에서만.

순서: 직군 → 연차 → JD 링크 → 포트폴리오 → 집중 프로젝트 → 분석. 뒤로가기(backRequested)는 popLast, 닫기(closeRequested)는 delegate(.dismiss), 분석 완료(completed)는 delegate(.finished) — dismiss/finished 구분은 AppFeature 가 이탈/완료를 다르게 처리하기 위함. 총 스텝 수는 `OnboardingFeature.totalSteps = 5` 단일 소스. @Reducer enum 이 만드는 Path.State 는 Equatable 을 자동 채택하지 않아 명시 채택한다. → [[app]]

## 직군 선택

STEP 1 (필수). 진입 시 JobClient.jobs 로 선택지를 로드해 칩으로 나열하고, 하나를 고르면 '계속하기'가 활성화된다. 완료 시 선택 직군의 jobRole(서버 enum, 예 "BACKEND")을 delegate 로 올린다. 이 스텝만 하단 CTA 가 단일 버튼이다(첫 스텝 — 이전 없음).

- 실패 UX 미정: jobsLoadFailed 는 로딩 해제만 (TODO).

## 연차 입력

STEP 2 (필수). 문장형 휠 피커 «내 경력은 [휠] 이다.» — 선택지 5개(신입~3년 이상, CareerOption). 휠은 native Picker 가 아니라 iOS 17 ScrollView(viewAligned + scrollPosition) 커스텀. 항상 값이 있어 CTA 상시 활성. 서버 연차 enum 미정 — rawValue 임시.

이 스텝부터 하단 CTA 가 «이전으로 | 계속하기» 2분할 바(가운데 dsGray700 구분선)이고, 내비바에는 닫기(X)만 있다 — 뒤로가기는 하단 바 담당 (STEP 2~5 공통 골격).

## JD 링크

STEP 3 (선택 — 스킵 가능). 탭 «JD 붙여넣기 / 직접 입력하기»는 화면 전환이 아니라 State 의 InputMode. 링크 입력은 600ms 디바운스 후 JDClient.validate — 로딩/에러/성공을 LinkValidation 하위 상태로 표현하고 필드 하단 4px 스트립 색으로 구분한다. 결과는 delegate(.continueRequested(JDSubmission?)) — .link/.text/nil(스킵).

- 성공 후엔 직접입력 탭 비활성, 검증 중 계속하기 무시.
- 카피 3곳(헬퍼·에러 fallback)·직접입력 200~3,000자 검증은 TODO.

## 포트폴리오 업로드

STEP 4 (필수). PDF 1개(최대 20Mb)를 fileImporter 로 받아 PortfolioClient.register → PROCESSING 이면 3초 간격 status 폴링 → READY/FAILED. idle/uploading/failed/uploaded 를 UploadState 하위 상태로 표현, uploaded 일 때만 계속하기 활성. 파일 제거(X)는 폴링 취소 + 서버 delete.

- 완료 행 디자인 미확인(진행 스트립만 뺀 근사) · 진행률 이벤트 없어 스트립은 고정 비율 · 재시도 시 PORTFOLIO_ALREADY_EXISTS 서버 정책 확인 필요 · 폴링 상한 없음 (전부 TODO).

## 집중 프로젝트

STEP 5 (선택 — 마지막 수집 스텝, 프로그레스 5/5). 300자 자유 입력 + «나중에 등록해도 괜찮아요!» 툴팁. 빈 입력·공백만이면 nil(건너뜀)로 올린다. 필드는 InterviewConfig.freeText(10~300자)에 대응 — 하한 10자는 서버 위임.

## 분석

종결 화면 (프로그레스·뒤로가기 없음, 다크 풀스크린). 코디네이터가 누적 OnboardingData 를 init 으로 주입 — 여기가 서버 제출 지점(TODO: API 연결, 현재 clock 시뮬레이션 3s+2s). 분석 중(스피너 체크리스트 3줄) → 완료 자동 전환 → delegate(.completed). X 는 분석 중에도 이탈 가능하며 pop 시 clock effect 자동 취소.

## 수집 데이터

OnboardingData — 위저드가 스텝을 거치며 채우는 공유 페이로드. 코디네이터가 소유하고 각 스텝 delegate 결과를 누적, 분석 스텝에 통째로 주입된다. 필드: userName(주입) · jobRole · career · jdLink/jdText(상호 배타) · portfolioId · freeText.

## 스텝 템플릿

OnboardingPlaceholderStepFeature/View — 스텝 골격(내비바·프로그레스 바·CTA) 템플릿. 실제 스텝 6개가 모두 붙으면서 코디네이터 Path 에서는 빠졌고, 새 스텝 추가 시 복사 출발점으로만 남아 있다 (view/inner/delegate 3분류, delegate 로 continue/back/close 만 통보).

## 코디네이터 연결

FeatureOnboarding 은 아직 AppFeature 에 배선되지 않았다. 배선 시: 닉네임(userName) 주입, delegate(.dismiss) → 중도 이탈 처리, delegate(.finished) → 메인 진입. Example 앱은 전체 위저드를 스텁 의존성으로 구동하며 ONBOARDING_START_STEP 환경변수로 특정 스텝부터 시작할 수 있다. → [[app]]
