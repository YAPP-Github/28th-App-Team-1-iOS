# 홈 & 회원가입·계정 상태 — 작업 문서 (PRD Part 6·7 → 우리 아키텍처 매핑)

> 「[PRD] Part6. 홈화면」 + 「[PRD] Part7. 회원가입·계정 상태 화면 정의」(2026-07-30 수령)를
> 이 레포의 **Tuist TMA + 순수 TCA** 규칙에 녹인 병합 작업 문서. 두 PRD 를 합친 이유: 홈이 앱의 첫 화면이자
> 가입 플로우의 착지점이라 흐름이 한 덩어리다.
> 화면 구성·명명은 2026-07-31 구두 확정(§0 표) — **UI 는 Figma 시안 수령 시 연결**(figma-screen 스킬 경로).
> 절대 규칙: **Feature→Feature 의존 0 · Client 는 Domain 모듈 Interface/Implementation 분리 · cross-feature 조립은 [[app]](AppFeature)에서만.**
> 면접 위저드/세션 매핑은 [ai-interview](ai-interview.md), 리포트는 [ai-interview-report](ai-interview-report.md).

## 0. 화면 인벤토리 → 레이어 매핑 (확정 화면명 — 2026-07-31)

가입·계정 화면은 전부 **`FeatureAuth`** — 기존 Auth 에 붙여 확장하고, 가입 온보딩(`AuthOnboarding*`)은 `Sources/Onboarding/` 하위 폴더로 그룹핑(단일 모듈 유지 — D3, 폴더링만). 홈은 기존 **`FeatureHome`** 확장.

화면 골격(리듀서·전환·mock 수준 뷰)은 2026-07-31 생성 완료 — 아래 «골격 ✅» 는 **UI(Figma)·API 배선만 남았다**는 뜻.

| 화면 (확정명) | PRD 대응 | 소유·구현 | 상태 |
|---|---|---|---|
| `Splash` | SP — 자동 로그인 판정 | FeatureAuth `SplashView`(정적) + `AppFeature.onAppear` 판정 배선 | 골격 ✅ 판정 ✅ |
| `AuthCreateAccount` | A0 로그인 | FeatureAuth — 기존 AuthFeature 를 `AuthCreateAccountFeature` 로 개명(D5 3분류 정리), 코디네이터 `AuthFeature` 신설 | 골격 ✅ / 🔴 신규·기존 분기(S-1)·실패 토스트 |
| `AuthTerms` | A1 약관 동의(5종) | FeatureAuth — 5종 체크·전체 동의·전문 바텀시트(DS `.hilitBottomSheet`) 동작 | 골격 ✅ / 🔴 제출 API(S-1)·전문(S-2) |
| `AuthSuspension` | A4 정지(블랙리스트) 안내 | FeatureAuth — 진입은 홈 게이트 `ACCOUNT_SUSPENDED` → cross-feature 제시 (§4) | 골격 ✅ / 🔴 게이트 배선·CS 주소 |
| `AuthOnboardingNaming` | (PRD Part7 밖 — 디자인 확정) 이름 입력 | FeatureAuth/Onboarding — DS `NameField` | 골격 ✅ / 🔴 `registerName`·`checkName` 배선 |
| `AuthOnboardingJob` | Part1 S0a 직군 선택 | FeatureAuth/Onboarding — FeatureOnboarding STEP1 **복사**(원본은 위저드 정리 시 제거) | 골격 ✅ |
| `AuthOnboardingExperience` | Part1 S0b 연차 선택 | FeatureAuth/Onboarding — FeatureOnboarding STEP2 **복사** | 골격 ✅ |
| `AuthOnboardingRegister` | 등록 완료 (PRD «가입 완료 화면 없음» 을 디자인이 뒤집음) | FeatureAuth/Onboarding — 완료 후 `delegate(.signedIn)` | 골격 ✅ / 🔴 프로필 제출 시점 미결 |
| 홈 — **두 덩어리(홈 3화면 + 면접 시작 3화면)** (§3) | Part6 전체 | FeatureHome — `Sources/Home/`(`HomeFeature.phase`) + `Sources/StartInterview/`(`StartInterviewFeature`, cover present) | 골격 ✅ / 🔴 로드 4종·위젯 UI |
| A2 권한 안내 | Part7 | **Out — AOS 전용.** iOS 는 사용 시점 요청 (Part2 준비 화면 게이트 ✅, [[interview#권한]]) | — |
| A3 재동의 | Part7 | MVP 미도안 — 분기 자리만 예약 | 🟡 |
| 로그아웃·탈퇴 | Part 5 소유 (탈퇴 완료 → `AuthCreateAccount` 복귀만 계약) | 참고 | — |

**기존 FeatureOnboarding 영향**: 직군·연차 스텝이 가입 플로우로 이동하면 면접 위저드는 JD·포폴·집중 프로젝트·분석 중심으로 남는다 — S0 은 가입 때 받은 프로필 값으로 스킵/프리필(미결 §7). 화면 코드 이동 vs 복사는 구현 시 결정.

## 1. 전체 흐름 (iOS — A2 없음)

```
Splash (앱 실행 시 항상 — 자동 로그인 판정)
 ├─ 세션 토큰 유효 ──▶ 홈 직행
 └─ 토큰 없음·무효 ─▶ AuthCreateAccount (카카오/Apple)
      │ 소셜 인증 + login 교환 성공
      ├─ 신규 ─▶ AuthTerms ─▶ AuthOnboardingNaming ─▶ AuthOnboardingJob
      │            │           ─▶ AuthOnboardingExperience ─▶ AuthOnboardingRegister ─▶ 홈
      │            └ 중도 이탈 → 계정 미생성, 재로그인 시 AuthTerms 재진입
      ├─ 기존 · 동의 최신 ─▶ 홈
      └─ 기존 · 동의 구버전 ─▶ A3 재동의 (MVP 미도안 — 자리만)

AuthSuspension — 정지 계정이 면접 시작 시도 시 (게이트 ACCOUNT_SUSPENDED, §4)

홈 (단일 화면 — phase 스위치, §3)
   ┬ 잔여 "N회 남음" (홈 단독 표시 — 마이페이지 미표시)
   ├ 위젯① [면접 연습 시작 | 이어서 진행] ─ 게이트 ─▶ §3 분기표
   ├ 위젯② 면접 기록 (foldable) ─ [레포트 보기] ─▶ 리포트 뷰 (r1/최종)
   └ 위젯③ 마이페이지로 이동 (Part 5)
```

⚠ 가입 온보딩 4화면(Naming~Register)의 순서·필수 여부는 Figma 수령 시 확정 — 위 순서는 구두 브리핑 기준. 이름·직군·연차 제출 시점(각 화면 즉시 vs Register 일괄)은 서버 계약과 함께 결정.

## 2. 회원가입·계정 상태 (Part 7)

### 확정 정책 (클라 영향분)

- 가입 수단: **카카오·Apple 소셜만**, 이메일 직접 가입 없음. 계정당 제공자 1개 고정. 소셜 로그인은 가입·로그인 미구분 — 첫 인증이면 가입 플로우.
- 필수 동의 **5종**(만 14세 / 이용약관 / 개인정보 수집·이용 / 면접 영상·음성 촬영·저장 / 국외 이전). 선택 동의 없음(마케팅 MVP 미수집) — A1 에 5종 외 체크박스 추가 금지.
- **A0 하단은 비운다**(2026-07-29 확정 — 간주 문구·열람 링크 모두 없음, 열람은 A1 [보기] 전담).
- 계정 정지 = **면접 시작만 차단**(게이트 1 `ACCOUNT_SUSPENDED`). 로그인·레포트 열람·마이페이지·탈퇴는 허용 — 정지여도 A0/홈은 정상.
- 휴면 정책 없음. 탈퇴 후 재가입 = 신규와 완전 동일(서버 식별 불가 — "다시 오셨네요" 류 불가).

### Splash (SP)

앱 실행 시 항상. 자동 로그인 판정 중 표시 — `AppFeature` 루트 게이트(`State.isAuthenticated`)를 `authClient.isAuthenticated()` 초기값으로 배선([[auth]] 다음 작업과 동일 항목). 토큰 유효 → 홈, 없음·무효 → AuthCreateAccount. 만료 세션은 기존 `LOGIN_EXPIRED` 전파(→ [[api#토큰 수명주기]])가 재로그인 라우팅 신호.

### AuthCreateAccount (A0 로그인)

`AuthCreateAccountFeature`/`View` 로 개명 완료(D5 3분류 정리 — 카카오·Apple 버튼, signIn→login 교환, 취소 조용히 복귀 동작). PRD 로 확정된 추가분:

| 인증 결과 | 이동 | 상태 |
|---|---|---|
| 신규 (서버에 소셜 식별자 없음) | A1 약관 동의 | 🔴 login 응답에 신규/기존·동의 버전 판별 계약 필요 (S-1 연계) |
| 기존 + 동의 최신 | 홈 (`delegate(.signedIn)` — 기존 경로) | ✅ |
| 기존 + 동의 구버전 | A3 재동의 (MVP: 자리만) | 🟡 |
| 사용자 취소 | A0 유지, 안내 없음 | ✅ (`AuthError.cancelled`) |
| SDK·네트워크 오류 | **토스트** "로그인에 실패했어요. 다시 시도해주세요" + A0 유지 | 🔴 현재 alert — 토스트로 교체 |

### AuthTerms (A1 약관 동의)

진입: 첫 소셜 인증 직후 1회. `FeatureAuth` 내부 화면 — 코디네이터 `AuthFeature` 의 `Path`(StackState)로 push (도메인 내부 내비). 골격 구현 완료([[auth#가입 플로우]]).

- 구성: 제목 «서비스 이용을 위해 동의가 필요해요» / [전체 동의] / 필수 5종 체크 / [보기] = **전문 바텀시트 — DS `.hilitBottomSheet` 껍데기 ✅ 사용**(딤 오버레이만 제공, 시트 판은 호출부) / [동의하고 시작하기] — **5종 모두 체크 시에만 활성**, 일부 체크 시 비활성(별도 경고 없음).
- 제출 = 서버가 **계정 생성 확정 + 무료 3회 부여 + 동의 이력(항목·버전·일시) 저장** — 이용권 D3(부여 시점) 이 이 정의로 자동 확정. API 는 `DomainAuth` 확장 🔴 (S-1: 인증~동의 사이 임시 토큰 상태 서버 협의).
- 제출 성공(iOS) → **가입 온보딩(AuthOnboardingNaming~)으로 진행** (PRD 는 «홈 직행»이었으나 디자인이 온보딩 4화면 경유로 확정. A2 없음 — 권한은 면접 시작 시점). 제출 실패(네트워크) → 토스트 + 화면 유지 + **체크 상태 보존**.
- 중도 이탈(뒤로가기·종료) → 계정 미생성. 재로그인 시 AuthTerms 재진입 — 클라 저장 없음, 서버 판정 수신만.
- 국외 이전 전문은 벤더 답변 대기(S-2) — 화면 뼈대·나머지 4종 전문 먼저.

### 가입 온보딩 — AuthOnboarding* (FeatureAuth/Sources/Onboarding/)

AuthTerms 제출 후 이어지는 4화면. AuthFeature 도메인 내부 내비(자체 `Path`/`StackState`) — cross-feature 아님.

| 화면 | 내용 | 구현 재료 |
|---|---|---|
| `AuthOnboardingNaming` | 이름 입력 | `UserClient.registerName`(1~20자)·`checkName`(중복 확인) ✅ — [[api#User]] |
| `AuthOnboardingJob` | 직군 선택 | 기존 FeatureOnboarding STEP1(JobSelection — `JobClient.jobs` 칩) 이관 |
| `AuthOnboardingExperience` | 연차 선택 | 기존 FeatureOnboarding STEP2(CareerInput — 문장형 휠 0~10년) 이관 |
| `AuthOnboardingRegister` | 등록 완료 | 신규 — 완료 후 홈 진입 (`delegate` → AppFeature) |

- 직군·연차 제출은 `UserClient.updateProfile` 후보 ✅ — 각 화면 즉시 저장 vs Register 일괄은 서버 계약과 함께 확정(§1 ⚠).
- 이관 시 기존 면접 위저드([[onboarding]])는 S0 두 스텝을 잃고 JD 부터 시작 — 프로필 프리필/스킵 처리 미결(§7).

### A3 재동의 — MVP 미도안 (서버만 고려)

화면은 안 그린다(디자인 협의 확정). 클라는 **분기 자리만 예약**: ① login 응답 «동의 구버전» 판정 ② 면접 시작 게이트 3 `CONSENT_VERSION_STALE` 폴백. 확정 구성(요약 없음 — 바뀐 항목 체크 + 전문 보기 + 동의/나중에)·«나중에 = 면접 시작만 차단» 은 첫 개정 시점 구현.

### AuthSuspension (A4 이용 제한·정지 안내)

진입: 면접 시작(위젯①)에서 게이트 1 `ACCOUNT_SUSPENDED` 수신 시 — **면접 시작 경로에만** 나타난다. 화면은 `FeatureAuth` 소속(블랙리스트 사용자 제한) — 발원지가 홈이므로 **cross-feature**: Home `delegate` → AppFeature 가 제시(§4). 전면/모달 여부는 디자인 확정 대기.

- 구성: 제목 «면접 이용이 제한되었어요» / 사유 «비정상적인 이용 패턴이 반복 확인되어 면접 시작이 제한되었어요» (**내부 용어 노출 금지** — NETWORK_DISCONNECT 등) / [메일 보내기](mailto CS) / [홈으로 돌아가기].
- 정지 검토·수동 정지/해제는 운영 소관 — 클라 로직 없음.

## 3. 홈 (Part 6) — 단일 화면 + phase

**화면 4종이 아니라 화면 1개** — Figma 프레임 4종(`HomeDefault`·`HomeReport`·`HomeStartInterview`·`HomeDuringInterview`)은 같은 화면의 상태 변형이다. `GuestFeedbackFeature` 패턴 채택: `State.phase` enum 하나로 상태를 관리하고 뷰가 phase 스위치로 서브뷰를 연결한다(→ `FeatureGuestFeedback/Sources/GuestFeedbackFeature.swift`).

**구현 시 수정 (2026-07-31)** — 시안을 받고 두 덩어리로 쪼갰다: «홈»(`HomeDefault` + `HomeReport` 2변형 = `State.phase`)과 «면접 시작»(시안 3장 = `StartInterviewFeature`, 홈 위로 cover present). `HomeDuringInterview` 는 **MVP 제외** — 화면·phase 케이스 모두 삭제(아래 표·`Phase` 스케치의 During 행은 결정 기록으로 남긴다).

| Figma 프레임 | 상태 의미 (구두 브리핑 — Figma 수령 시 확정) |
|---|---|
| `HomeDefault` | 기본 상태 |
| `HomeReport` | 면접 기록(레포트) 표시 상태 — 구현은 «오랜만이에요 OO님!» 인사말 표시 여부 2변형(`returning`/`recent`) |
| `HomeStartInterview` | 시작 CTA 변형 — 처음 / 등록 포폴 있음 / 무료 횟수 모두 사용. **phase 아니라 present** (홈 탭에 NavigationStack 없음) |
| `HomeDuringInterview` | 진행 중 면접 있음 / 레포트 제작 시점 — **MVP 제외 (2026-07-31 삭제)** |

구성(위→아래): **잔여 "N회 남음" → 위젯① 면접 연습 진행(주 CTA) → 위젯② 면접 기록 → 위젯③ 마이페이지**. 위계: 핵심 행동(연습 시작) 최대, 동기(기록·잔여) 곁에, 관리(마이페이지)는 진입점만.

«위젯» = 홈 안의 카드형 기능 블록(OS 위젯 아님). 보관함 탭 폐기·스트릭·알림 배너·페이월은 MVP Out.

### 위젯 ① 면접 연습 진행

기본 [면접 연습 시작], held 세션 존재 시 **[이어서 진행]** 으로 전환(숨기면 슬롯 잠김 혼란 — 같은 `session_id` 복귀 확정). 탭 시 이용권 게이트(`checkStartEligibility` — 이용권 PRD 7장 계약 재사용: 7.2 사전확인 선택·7.3 원자적 시작·Idempotency-Key. **홈은 새 계약을 만들지 않는다**):

| 게이트 결과 | 행선지 | 조립 |
|---|---|---|
| 통과 | 온보딩 위저드 S0~ (직군·연차는 프로필 프리필 가능 — 미결) → 세션 생성 → 면접 | cross-feature — 기존 dev 버튼 경로의 정식화 |
| held 세션 | [이어서 진행] → 같은 session_id 로 Part 2 복귀 (`InterviewFeature.State(sessionId:)` — [ai-interview](ai-interview.md) 작업 D 와 합류) | cross-feature |
| `NO_REMAINING` | «무료 횟수를 모두 사용했어요» 안내 (MVP 후 페이월 자리) | 홈 내부 |
| `PORTFOLIO_NOT_READY` | 포폴 등록(S2) 라우팅 — 교체 소진 시 «다음 달 1일부터 업로드 가능» 병기 | cross-feature (S2 강제 라우팅 — [ai-interview](ai-interview.md) §2 표와 동일 메커니즘) |
| `CONSENT_*` | 동의 플로우 (A3 자리 — §2) | 예약 |
| `ACCOUNT_SUSPENDED` | `AuthSuspension` 정지 안내 (§2) | cross-feature — AppFeature 제시 |
| 기타 (`RATE_LIMITED` 등) | 각 안내 | 홈 내부 |

### 위젯 ② 면접 기록 (마이페이지 PRD 3.3·3.4 이관)

세션당 1행·최신순, MVP 최대 3~4행 전체 노출(페이지네이션 없음). 행 탭 → 펼침(foldable, 재탭 접힘) = 메타데이터 + [레포트 보기].

| 행 상태 | 조건 | 펼침 후 [레포트 보기] |
|---|---|---|
| 1차 레포트 | 지인 피드백 0건 | 상세 리포트(r1) 뷰 |
| 최종 레포트 | 지인 피드백 1건 이상 — **도착 즉시 갱신, 확정 시점 없음** | 최종 레포트 뷰 + «마지막 업데이트» 시각 |
| 레포트 생성 실패 | 생성 영구 실패 (**미차감**) — 종료 상태, 자동 재생성 없음 | 진입 버튼 없음. «레포트 생성에 실패했어요 · 횟수는 차감되지 않았어요» |

메타데이터(전부 **세션 스냅샷** 값): 직군·연차(면접 당시 값) / 포트폴리오 파일명(원본 삭제 시 «삭제된 포트폴리오» 배지 + 파일명 유지) / JD(url 문자열 또는 «JD 직접 입력») / 시각 4종(서버 시간 — 면접 진행·레포트 생성·지인 피드백 요청·최종 마지막 업데이트).

[레포트 보기] → `InterviewReportFeature` 는 cross-feature — `delegate` → AppFeature 제시([ai-interview-report](ai-interview-report.md)).

### 잔여 무료 횟수 — 홈 단독 표시

서버 값 표시만(«진실은 서버에만»). 표기 «N회 남음» 뿐 — 진행 중 구분 없음. **마이페이지에는 표시하지 않는다.** 0회 도달 시 위젯① 이 NO_REMAINING 안내로 전환. 시작 버튼 옆이 제자리(판단 재료).

### 위젯 ③ 마이페이지로 이동

단순 진입 버튼 — 프로필(직군·연차)·포트폴리오 관리(Part 5 Feature — 미존재, delegate 자리만). 포폴 없으면 «포트폴리오 등록 필요» 표시 여부는 디자인 결정 — 위젯① PORTFOLIO_NOT_READY 의 예고 장치.

### 빈 상태 (첫 사용자)

잔여 «3회 남음»(계정 생성 시 부여) / 위젯① 탭 → 게이트 PORTFOLIO_NOT_READY → 포폴 등록(S2)부터 — **홈이 온보딩 진입점** / 위젯② 빈 문구(«아직 면접 기록이 없어요…» — 디자인 확정) / 위젯③ «포트폴리오 등록 필요».

## 4. Cross-feature 라우팅 (delegate → AppFeature)

```
Splash 판정(AppFeature 자체) ──isAuthenticated──▶ 홈 | AuthCreateAccount 루트 게이트
Auth --delegate(.signedIn)-------------------▶ AppFeature → 홈 (기존 ✅ — 가입 플로우 완성 후엔
                                               발원지가 AuthOnboardingRegister 완료 / 기존 회원은 login 분기)
Home --delegate(.startInterviewRequested)----▶ AppFeature — 게이트 결과별: 면접 위저드 fullScreenCover /
                                               S2 강제 / AuthSuspension 제시 / 홈 내부 안내
Home --delegate(.resumeInterviewRequested(sessionId))▶ AppFeature → InterviewFeature(sessionId) fullScreenCover
Home --delegate(.reportRequested(sessionId))-▶ AppFeature → InterviewReportFeature (r1/최종은 리포트 도메인 내부)
Home --delegate(.myPageRequested)------------▶ AppFeature → 마이페이지 (Part 5 — Feature 생기면)
Onboarding --delegate(.finished(sessionId:))-▶ AppFeature → 면접 시작 (기존 계약 — [ai-interview] §2)
```

기존 dev 임시 진입(`showsOnboardingEntry`·`showsDebugLogout`)은 위젯①·마이페이지(로그아웃은 Part 5)로 흡수되며 제거 예정.

## 5. Client / Domain 영향

홈 진입 시 4종 로드 — 묶음 API 1회 vs 기존 4회 호출은 서버 협의(미결 #1). 확정 전 Client 계약 착수 보류, 화면은 mock 선행.

| 데이터 | Client (모듈) | 상태 |
|---|---|---|
| 잔여 횟수 | `UserClient.profile` → `remainingTicketCount` ✅ 존재 — PRD 표기 `GET /me/entitlement` 와의 대응은 묶음 API 협의와 함께 확정 | ✅/🟠 |
| 면접 기록 리스트 | 신규 — 세션 스냅샷 + 레포트 상태(1차/최종/실패) + 시각 4종 + 포폴 삭제 여부. `DomainInterviewReport` 확장(`list`) 예상 | 🔴 서버 협의 |
| 진행 중(held) 세션 유무 | 신규 — `InterviewClient` 확장. held 세션 존재 시 신규 POST /sessions 처리도 미결 #3 | 🔴 서버 협의 |
| 포폴 상태 (위젯③·빈 상태) | `PortfolioClient.list` | ✅ |
| 시작 게이트 | 신규 — `checkStartEligibility`(사전확인·선택)· 사유 코드 `ACCOUNT_SUSPENDED`·`NO_REMAINING`·`PORTFOLIO_NOT_READY`·`CONSENT_VERSION_STALE`·`RATE_LIMITED`. 기존 `createSession` 에러(`NO_REMAINING_TICKET` 등 — [[api#Interview]])와 코드 체계 정리 필요 | 🔴 서버 협의 |
| A1 동의 제출 | `DomainAuth` 확장 — 계정 생성 확정+3회 부여+이력 저장. login 응답의 신규/기존·동의 버전 판별 포함 | 🔴 서버 협의 (S-1) |
| 자동 로그인 판정 | `AuthClient.isAuthenticated` | ✅ — AppFeature 배선만 |

HomeFeature 는 «외부 IO 없는 Feature 예시»([[home]])에서 벗어난다 — `.domain(interface:)` 의존이 생기는 첫 확장. 화면 상태는 서버 판정의 표시일 뿐(탭 시점 게이트가 진실 — TTL 레이스 미결 #4 도 «탭 시 재검증»으로 흡수 제안):

```swift
// 홈 화면 — GuestFeedback 패턴 (State.phase → 뷰 스위치). §3 «구현 시 수정» 반영 후 2종
public enum Phase: Equatable, Sendable {
    case `default`                       // HomeDefault
    case report(ReportVariant)           // HomeReport — 인사말 표시 여부가 축
    // case startInterview(Start)        // → StartInterviewFeature 로 분리 (cover present)
    // case duringInterview(During)      // → MVP 제외로 삭제 (2026-07-31)
}
public enum ReportVariant: Equatable, Sendable { case returning, recent }
// 면접 시작은 별 Reducer: StartInterviewFeature.Variant { first, hasPortfolio, exhausted }
// (삭제) During: Equatable, Sendable { case inProgress, reportGenerating } — MVP 제외
// 위젯② 행별 상태는 phase 와 별개 유지:
enum ReportRow { case first; case final(lastUpdatedAt:); case generationFailed } // + foldable 펼침 상태
```

## 6. 엣지 케이스 (병합 — 클라 판정분)

| 상황 | 처리 |
|---|---|
| 잔여 0 + 기록 3건 | 위젯① 소진 안내, 기록 열람은 그대로 — «다 썼어도 기록은 남는다» |
| 포폴 삭제 + 기록 존재 | 행 펼침에 «삭제된 포트폴리오» 배지, 위젯③ «포트폴리오 등록 필요» |
| 교체 소진 + 포폴 0 | PORTFOLIO_NOT_READY 안내에 «다음 달 1일부터 업로드 가능» 병기 |
| 지인 피드백 도착 직후 홈 복귀 | 해당 행 즉시 «최종» + last updated (홈 재진입 시 재조회로 실현) |
| 진행 중 세션 채로 홈 재진입 | 위젯① = [이어서 진행], 같은 session_id (표시 후 TTL 만료 레이스 → 미결 #4) |
| A1 동의 전 앱 종료 | 계정 미생성 — 재로그인 시 A1 재진입 (서버 판정) |
| 카카오·Apple 각각 가입 | 계정 2개 생김(막을 수 없음) — Part 5 제공자 배지가 완화 장치 |
| 정지 + 동의 구버전 겹침 | 게이트 순서상 정지(게이트 1) 우선 → A4 |
| 탈퇴 직후 같은 소셜 재로그인 | 신규와 동일(A1 부터), 과거 기록 안내 없음 |
| 재동의 [나중에] 후 면접 시작 | 게이트 3 차단 → A3 재진입 (MVP: 자리) |

## 7. 미결 & 블로커

| # | 항목 | 소유 | 클라 영향 |
|---|---|---|---|
| 6-1 | 홈 진입 API 묶음(1회) vs 기존 4회 | 서버 | 🔴 홈 Client 계약 블로커 |
| 6-2 | [이어서 진행]·위젯③ 미리보기·빈 상태 문구 | 디자인 | 🟡 문구 슬롯만 |
| 6-3 | held 세션 존재 시 신규 POST /sessions 처리 | 서버 | 🟠 resume 경로 확정 |
| 6-4 | [이어서 진행] 탭 시점 재검증(TTL 만료 → «세션 만료·미차감» 안내?) | 정책 | 🟠 탭 시 게이트 재호출로 흡수 제안 |
| S-1 | 소셜 인증~동의 제출 사이 서버 상태(임시 토큰)·«동의 제출=계정 생성» 계약 | 서버 | 🔴 A1 API 블로커 |
| S-2 | 국외 이전 동의 전문 | 벤더 대기 | 🟡 뼈대 먼저 |
| S-3 | 재동의 변경 요약 | — | 소멸 (2026-07-29 확정 — 첫 개정 시점 이월) |
| S-4 | 카카오 이메일 필수화(비즈앱) 여부 | PM | 🟠 미제공 시 차단/허용 분기 |
| S-5 | CS 이메일 주소 | 운영 | ✅ 확보 — AuthSuspension mailto |
| 신규 | 직군·연차가 가입 플로우로 이동 → 면접 위저드 S0 처리(스킵 vs 프리필) · 이름/직군/연차 제출 시점(화면별 즉시 vs Register 일괄) | PM·서버 | 🟠 위저드 개편 범위·API 계약 |

측정(위젯 클릭률·전환율·A1 완료율·재동의/정지 카운트)은 애널리틱스 도입 시 이벤트 설계로 이월([ai-interview](ai-interview.md) §5 와 동일 태도).

## 8. 수용 기준 (병합 — iOS 관련분)

1. 신규: AuthCreateAccount → 소셜 인증 → AuthTerms(5종 체크) → 제출 → 계정 생성·무료 3회·이력 저장 → 가입 온보딩(이름·직군·연차·등록 완료) → 홈 (iOS — A2 없음).
2. AuthTerms 이탈 후 재로그인 → AuthTerms 재진입, 계정·이용권 없음. 필수 5종 중 4개 체크 → 버튼 비활성.
3. 기존 회원 로그인 → 약관·온보딩 없이 홈. (동의 구버전 → A3 는 MVP 자리만.)
4. 첫 사용자 홈: 잔여 «3회 남음», 기록 빈 상태, 위젯① → 포폴 등록(S2) 라우팅.
5. 정상: 위젯① → 게이트 통과 → S0 프로필 직군·연차 프리필.
6. 진행 중 세션: 재진입 시 위젯① = [이어서 진행], 같은 session_id 복귀, 새 예약 생성 없음.
7. 잔여 0: 위젯① 소진 안내, 기록 열람 정상.
8. 기록 행 탭 → 펼침/재탭 접힘. [레포트 보기] → 1차=r1 / 최종=최종 뷰. 피드백 1건 도착 → 즉시 «최종»+last updated.
9. 생성 실패 세션 → «생성 실패·횟수 미차감» 행, [레포트 보기] 없음, 잔여 불변.
10. 포폴 삭제 후 → 행 배지 «삭제된 포트폴리오», 위젯③ «포트폴리오 등록 필요».
11. 잔여 횟수는 홈 단독 표시(마이페이지 미표시).
12. 정지 계정: 로그인·레포트 열람 정상, 면접 시작 시 A4 + CS 메일 버튼 동작.
13. 탈퇴 후 재가입 → A1 부터 신규 흐름, 무료 3회 재부여.

## 9. 빌드 순서 제안

UI 는 전 단계 공통으로 **Figma 시안 수령 후 연결**(figma-screen) — 그 전엔 리듀서·Path·phase 골격과 mock 데이터까지.

1. ~~**AppFeature 루트 게이트 확장**~~ ✅ 2026-07-31 — Splash + `isAuthenticated` 초기 판정 배선.
2. **FeatureAuth 가입 플로우** — 골격 ✅ 2026-07-31 (코디네이터 `AuthFeature` + 화면 6종 + Example 완주 데모, STEP1·2 는 복사). 잔여 🔴: 동의 제출·신규/기존 분기(S-1), 프로필 제출 시점, 실패 토스트, Figma UI.
3. **FeatureHome 개편** — phase 골격 ✅ 2026-07-31 (`Phase` 4종 + 서브뷰 스텁). 잔여 🔴: 진입 로드 4종·위젯 3종 UI·행 foldable·빈 상태 (리스트/게이트 API 전엔 mock + `UserClient.profile` 잔여만 실값).
4. **Domain 신규 계약** — 게이트·기록 리스트·held 세션 (미결 6-1·6-3·S-1 서버 협의 후).
5. **라우팅 배선** — 위젯①→면접 위저드/면접(작업 D 합류)·AuthSuspension, 위젯②→리포트, 위젯③→마이페이지(Part 5 대기). dev 임시 버튼 제거. 면접 위저드 S0 정리(§7 신규 미결 — 원본 STEP1·2 제거 포함).
