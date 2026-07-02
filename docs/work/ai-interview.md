# AI 면접 — 작업 문서 (기획서 → 우리 아키텍처 매핑)

> YAPP APP 1팀 「AI 면접 연습 앱」 기획서(Part 1 질문 생성 / Part 2 10분 음성 면접)를
> 이 레포의 **Tuist TMA + 순수 TCA** 규칙에 녹인 설계 작업 문서.
> 절대 규칙: **Feature→Feature 의존 0 · Repository(Client)는 Domain 모듈 Interface/Implementation 분리 · cross-feature 조립은 [[app]](AppFeature)에서만.**
> 시스템 전체 그림/결정 근거·Client 분리(D3)는 [[architecture]], 도메인 큰 그림은 [[domain.map]] 참고.
> 출처: Confluence 「Part1. 면접 질문 생성」 / 「Part2. AI와 10분 면접」 (기준일 2026-06-09)

## 0. 제품 → 레이어 매핑

| 기획 | Feature 모듈 | 도메인 내 navigation |
|---|---|---|
| Part 1 질문 생성(온보딩 위저드) | `InterviewSetupFeature` | 자체 `StackState` 위저드 (S0~S3.5) |
| Part 2 10분 음성 면접 | `InterviewSessionFeature` ★ | 단일 화면 + 턴 **상태머신** |
| 포트폴리오 관리(설정) | `PortfolioFeature` | — |
| Part 3 보고서/영상 복기 | `InterviewReportFeature` (R0·R1 + V0·V1·V2) | 자체 `Path` (R0→V0→V1→V2→R1) → [ai-interview-report](ai-interview-report.md) |
| Part 4 사람 평가(유료) | (후속, 별도) | — |

★ = 엔지니어링 리스크 집중 지점.

## 1. 모듈 의존 그래프

```
App  (composition root — 레이어 umbrella link → liveValue 활성화)
└── AppFeature  (코디네이터: 탭 + Setup→Session→Report 라우팅)
    ├── InterviewSetupFeature ──┬ DomainQuestionInterface
    │   └ Path: jobYears(S0)    ├ DomainPortfolioInterface
    │          jd(S1)           └ SharedDesignSystem
    │          portfolio(S2)
    │          projectSelect(S3)
    │          loading(S3.5)
    ├── InterviewSessionFeature ┬ DomainQuestionInterface
    │   (턴 상태머신)            ├ DomainSpeechInterface     (TTS + STT)
    │                           ├ DomainRecordingInterface  (A/V 캡처·보존)
    │                           ├ DomainPermissionInterface
    │                           └ SharedDesignSystem
    ├── PortfolioFeature ─────── DomainPortfolioInterface · SharedDesignSystem
    └── InterviewReportFeature ─ DomainScoringInterface · SharedDesignSystem
```

단방향 DAG. `Setup`은 `Session`을, `Session`은 `Report`를 **import하지 않는다** — 기존 Users→App→Profile 핸드오프 패턴([[domain.map]])과 동일.

## 2. Cross-feature 라우팅 (delegate → AppFeature)

```
Setup   --delegate(.startInterview(config))--▶ AppFeature --fullScreenCover--▶ Session
Session --delegate(.finished(result))--------▶ AppFeature --dismiss + present--▶ Report
Session --delegate(.aborted)-----------------▶ AppFeature --dismiss (기록 폐기)
설정 Portfolio --delegate(.emptied)----------▶ AppFeature --다음 연습 진입 시 S2 강제 라우팅
```

→ `@lat`: [[app#Cross-feature Routing]] · import에 안 보이는 의존이므로 변경 시 이 표 기준으로 영향 추적.

## 3. Client 설계 (외부 IO — Domain 모듈 Interface/Implementation 분리, [[architecture]] D3)

| Client | 책임 | 핵심 시그니처(요지) | 소비처 |
|---|---|---|---|
| **PortfolioClient** | PDF 업로드·OCR·연관성·CRUD | `upload(pdf)→Portfolio` (전송만) · `processOCR(id)` · `checkRelevance(id, projectText)→RelevanceResult` · `fetchCurrent()→Portfolio?` · `delete(id)` | S2·S3.5·설정 |
| **QuestionClient** | AI 질문 엔진 | `firstQuestion(config)→Question` · `followUp(TurnContext)→Question?` (연차별 3/5단계 depth는 서버, 클라는 context 전달) | S3.5·Part2 |
| **SpeechClient** | 음성 입출력 | `speak(text)→AsyncStream<TTSEvent>` · `transcribe()→AsyncStream<Transcript>` (partial/final + **confidence**) · `stop()` | Part2 |
| **PermissionClient** | 카메라·마이크 권한 | `status()` · `request()→Bool` | P0 |
| **RecordingClient** | A/V 캡처 + 30일 보존 | `start(sessionId)` · `stop()→RecordingRef` | P1·P4 |
| **ScoringClient** | 세션 제출·보고서 | `submit(session)` · `report(id)→Report` | P4·Part3 |

규칙: 각 Client 는 **Domain 모듈**(`DomainQuestion` 등 — `make scaffold-domain name=Question`), `testValue`는 전부 `unimplemented`(빈 클로저 금지).
SpeechClient는 책임이 커지면 `TextToSpeechClient` / `SpeechRecognitionClient`로 분리 가능하게 시그니처를 나눠 둔다.

## 4. 도메인 모델 (각 Domain 모듈 Interface)

```swift
enum JobRole { case dev, pm, designer, other }
struct InterviewConfig { let role: JobRole; let years: Int; let jd: String   // ≤3000자
                          let focusProjectText: String; let portfolioId: Portfolio.ID }   // 위저드 산출물
struct Portfolio: Identifiable { let id; var fileName; var uploadedAt; var sizeBytes; var pageCount; var ocrStatus }
struct InterviewQuestion: Identifiable { let id; let text; let stage: Int  // 1~5 STAR 깊이
                                          let isFollowUp: Bool }
struct InterviewTurn { let question; var transcript; var confidence: Double; var status }  // answered/skipped/silentTimeout
struct InterviewSession: Identifiable { let id; let config; var turns: [InterviewTurn]; var endStatus }  // completed/aborted
struct RelevanceResult { let isRelevant: Bool; let reason: String? }
```
모듈 경계 넘는 타입은 전부 `public`(+`init`), `Equatable`/`Sendable`/`Codable` 기본.

## 5. Part 1 — `InterviewSetupFeature` (위저드)

S0→S3는 **도메인 내부** navigation → 규칙대로 자체 `Path` + `StackState`. 루트가 누적 `draft`를 들고, 각 step은 입력만 받아 위로 신호.

```swift
@ObservableState struct State {
    var draft = SetupDraft()              // role·years·jd·focusText 누적
    var portfolio: Portfolio?             // 있으면 S2 skip
    var path = StackState<Path.State>()   // jobYears→jd→portfolio→projectSelect→loading
}
enum Action {
    case onAppear                         // fetchCurrent → 포폴 유무로 첫 step 분기
    case path(StackActionOf<Path>)
    case delegate(Delegate)
    enum Delegate { case startInterview(InterviewConfig) }   // S3.5 통과 → AppFeature가 Part2 제시
}
```

핵심 분기(기획서 그대로):
- **포폴 0개 → S2 강제**, 있으면 skip(반복 연습은 "포폴 확인 카드"만).
- **S3.5 통합 로딩**: 첫 연습 = `processOCR` + `checkRelevance`(30초~2분, 면접 철학 콘텐츠 노출) / 반복 = `checkRelevance`만(짧음).
- **연관성 실패 → S3 재입력 루프**. 근거 노출·강제 진행·경고 톤은 product 결정(논의 #6) → State에 `relevanceReason` 자리만 마련.

## 6. Part 2 — `InterviewSessionFeature` ★ 핵심 난이도

**겹치는 타이머 + 실시간 오디오 스트림 + 인터럽트**가 한 reducer에 모인다. TCA 정석 레시피:

### (a) 턴 phase = 명시적 enum 상태머신
```swift
enum Phase {
    case preparing                        // P0 권한
    case asking(InterviewQuestion)        // 질문 TTS 재생 (마이크 일시정지)
    case thinking(remaining: Int)         // 5초 카운트다운
    case answering(lastSpeechAt: Double?) // 녹음 + 실시간 STT
    case fillerTransition                 // 턴 사이 필러 TTS
    case wrappingUp                       // 8:45+ 랩업 (새 질문 금지)
    case finished(EndStatus)
}
```

### (b) 질문 텍스트는 State에만, View엔 노출 X
디자인 방향성 = **TTS-only**. View는 `visibleStatus`(듣는중/생각중/말하는중/카운트다운)만 그린다.

### (c) 모든 타이머·스트림은 취소 가능 effect, CancelID로 관리
```swift
enum CancelID { case session, thinking, silence, tts, stt, hardCap }
@Dependency(\.continuousClock) var clock
@Dependency(\.speechClient) var speech
```
- **세션 시계**(0.1s tick): 누적 시간 → `8:00 수동종료 활성` · `8:45 wrappingUp` · `12:00 hard cap 강제종료`.
- **TTS**: `speak(q.text)` 스트림 `.finished` → `thinking(5)` 시작.
- **5초 생각**: 카운트다운, 먼저 말하면(STT partial 수신) 즉시 `answering` 점프(②→③).
- **STT**: `transcribe()` partial마다 `lastSpeechAt` 갱신 + `silence` 타이머 리셋.
- **종료 판정**(④): 발화 후 10초 침묵 → `endTurn(.answered)` / 무발화 15초 → "질문 다시?" / 임계 미만 침묵 → 대기.
- **SKIP**(⑤)·**재청취**(⑥)·**필러**(⑦)는 별도 action.

### (d) 세션 무결성 — P2 중단 = 폐기
`scenePhase` + `AVAudioSession` interruption(전화·백그라운드·네트워크) 구독 → 모든 CancelID cancel + recording 폐기 + `.delegate(.aborted)`. (논의 N: 전화 차단 기술적 불가하면 이 경로 확정.)

### (e) STT 30% 실패(P3)
`Transcript.confidence` 턴별 집계 → 임계 초과 시 세션 초기화. (논의 H/I: 측정식·귀책분리는 인터페이스가 confidence/무음비율을 주는지에 의존 → confidence 필수.)

### 꼬리질문 depth (기획서 §3)
0~4년차 = 한 프로젝트 3단계 / 5년차+ = 5단계. 10분 최대 10질문. STAR 5단계(의사결정 맥락 → 트레이드오프 → 실패·모호함 → 성공지표 모호함 → 응용)는 `QuestionClient.followUp`이 `TurnContext`(직전 답변 transcript + stage)로 서버에 위임.

## 7. 기획서 "논의할 문제" → 아키텍처 영향도

빌드 전 **반드시 잠가야 하는(load-bearing)** 것:

| 항목 | 영향 | 잠그는 시점 |
|---|---|---|
| **TTS-only** (Part2 디자인방향성·P1#9) | SpeechClient에 TTS 필수 + 5/15초 타이밍이 TTS *완료* 기준 | 🔴 Session 착수 전 |
| **E** 10질문 vs 3·5단계 배분 / **F** 복수 프로젝트 지정 | `followUp` depth·예산 로직, 턴 루프 종료 조건 | 🔴 Session 착수 전 |
| **N** 전화 수신 차단 가능? | P2 abort 경로(구독 vs 차단) | 🔴 Session 착수 전 |
| **H/I** STT 30% 측정·귀책 | SpeechRecognition confidence 제공 여부 | 🟠 인터페이스 확정 시 |
| **A** 정상완료 vs 포기 구분 | `EndStatus` + Scoring 트리거 | 🟠 P4 착수 전 |
| **J** Scoring 시점(Part2/3 경계) | Session→Report delegate 계약 | 🟠 P4 착수 전 |
| #5 PDF 상한 / #8 OCR 폴백 | PortfolioClient 에러 모델 | 🟡 Setup 단계 |
| 카운트다운·상태 인디케이터·토스트 | SharedDesignSystem 컴포넌트 추가 | 🟡 병행 |

## 8. 빌드 순서 (CLAUDE.md "새 모듈 추가 흐름"에 정렬)

1. **Domain 모델 + SharedDesignSystem** — 위 도메인 타입 + 면접 전용 컴포넌트(`CountdownRing`, `SpeakingIndicator`, 상태 토스트)
2. **Domain Clients = Interface 먼저**(Implementation 은 stub) — Portfolio·Question·Speech·Permission·Recording·Scoring, `testValue` unimplemented
3. **InterviewSetupFeature** — Question/Portfolio testValue로 위저드 전체 테스트
4. **InterviewSessionFeature** ★ — mock SpeechClient(스크립트 AsyncStream) + `TestClock`로 상태머신 결정론 검증. 디바이스 의존 전에 Example 앱 + 단위테스트로 격리
5. **PortfolioFeature**(설정 관리)
6. **AppFeature 배선** — delegate 수신 + fullScreenCover 체인
7. **InterviewReportFeature** stub → Part 3 본격화

## 9. 미정/후속

- ~~Part 3 Scoring 입출력 스키마 (보고서 항목) — 별도 기획 필요~~ → 기획서 나옴, 설계 완료 [ai-interview-report](ai-interview-report.md) (ScoringClient 확장 + PlaybackClient·ReviewClient 신규)
- Part 4 사람 평가 연계 + 유료 게이팅(논의 L)
- 탭 구성(연습/기록/설정) — 제품 IA 확정 시 [[domain.map]] 갱신
