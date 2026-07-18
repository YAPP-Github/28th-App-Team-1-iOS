# 온보딩 도메인 — 신규 사용자 셋업 위저드 (FeatureOnboarding)

가입 직후 프로필을 수집하는 멀티스텝 위저드 (Figma «STEP N_…» 기준). 코디네이터가 스텝을 조율하고, 각 스텝은 독립 리듀서+뷰(Onboarding<StepName>)로 분리된다. 현재 STEP 1(직군 선택)만 실제 구현이고 STEP 2+ 는 템플릿 stub 자리표시 상태 — 디자인이 오면 같은 패턴으로 채운다.

## 코디네이터

OnboardingFeature 가 위저드 루트. STEP 1(직군 선택)을 NavigationStack 루트로 두고, 이후 스텝은 `path`(StackState)로 push 한다. 각 스텝의 delegate 만 매칭해 공유 데이터를 누적하고 다음 스텝으로 전환한다 — 조립은 코디네이터에서만 (도메인 내 navigation = Path/StackState).

스텝 간 직접 의존은 없다. AppFeature 는 OnboardingView 하나만 제시하면 된다. → [[app]] Path enum 에 스텝별 case 를 추가하는 식으로 확장한다(예: `case career(OnboardingCareerFeature)`). @Reducer enum 이 만드는 Path.State 는 Equatable 을 자동 채택하지 않아 명시 채택한다.

## 직군 선택

STEP 1. 진입(onAppear) 시 JobClient.jobs 로 선택지를 로드해 칩으로 나열하고, 하나를 고르면 하단 '계속하기'가 활성화된다. 완료 시 선택 직군의 jobRole(서버 enum 값, 예 "BACKEND")을 delegate(.continueRequested)로 코디네이터에 올린다 — 코디네이터가 [[onboarding#수집 데이터]]에 저장하고 다음 스텝을 push. 이탈(X)은 delegate(.closeRequested) → 코디네이터가 종료.

- 프로그레스 바: step/totalSteps 로 렌더(코디네이터가 스텝별 step 주입).
- 선택 칩 강조·활성 CTA 색은 Figma 미확인 추정치(코드 TODO) — 디자인 확정 시 조정.
- 실패 UX 미정: jobsLoadFailed 는 로딩 해제만 (TODO).

## 수집 데이터

OnboardingData — 위저드가 스텝을 거치며 채우는 공유 페이로드. 코디네이터가 소유하고 각 스텝 delegate 결과를 누적한다. 현재 필드는 userName(주입)·jobRole(STEP 1). 마지막 스텝에서 이 값을 서버 제출 페이로드로 변환한다 — 스텝 추가 시 필드도 함께 늘린다.

## 스텝 템플릿

OnboardingPlaceholderStepFeature/View — STEP 2+ 자리표시. 내비바·프로그레스 바·하단 CTA 골격만 두고 본문은 비었다. 실제 스텝 디자인이 오면 이 파일을 복사해 Onboarding<StepName> 으로 채운다(구조 동일: view/inner/delegate 3분류, delegate 로 continue/back/close 만 코디네이터에 통보). 내비게이션이 실제 동작하는지 검증하는 용도도 겸한다.

## 코디네이터 연결

FeatureOnboarding 은 아직 AppFeature 에 배선되지 않았다. 배선 시: 닉네임(userName) 주입, delegate(.dismiss) 수신 → 온보딩 화면 종료가 필요하다. → [[app]]
