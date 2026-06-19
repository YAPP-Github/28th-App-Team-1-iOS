# AI 면접 Part 3 — 작업 문서 (분석 보고서 & 영상 복기 → 우리 아키텍처 매핑)

> YAPP APP 1팀 「AI 면접 연습 앱」 기획서 **Part 3 (AI 분석 보고서 & 면접 영상 다시보기)** 를
> 이 레포의 **Tuist µFeature + 순수 TCA** 규칙에 녹인 설계 작업 문서.
> [[ai-interview]] 에서 `InterviewReportFeature (지금은 stub)` 로 자리만 잡았던 도메인의 본설계.
> 절대 규칙: **Feature→Feature 의존 0 · Client만 Interface/Live 분리 · cross-feature 조립은 [[app]](AppFeature)에서만.**
> 시스템 전체 그림은 [[architecture]], 도메인 큰 그림 [[domain.map]], Client 분리 [[clients]], Part1/2 설계 [[ai-interview]].
> 출처: 「Part3. AI 분석 보고서 & 면접 영상 다시보기」 PDF (기준일 2026-06-15)

## 0. 제품 → 레이어 매핑

5개 화면이 한 도메인. 화면 코드 R = AI 리포트, V = 영상 복기. 전부 **`InterviewReportFeature` 하나** + 자체 `Path`.

| 기획 화면 | 역할 | Path step |
|---|---|---|
| **R0** 리포트 요약(최소) | 면접 직후 진입점. 강점1+개선점1+다음 재검증 영역 | (root) |
| **V0** 복기 진입/챕터 목록 | 질문 단위 챕터, "잘한 장면" 먼저 | `reviewChapters` |
| **V1** 영상+자기평가 ★ | 영상·대본·AI 근거 단일 시간축 | `reviewPlayer` ★ |
| **V2** 자기평가 입력 | 잘한점/아쉬운점/다음시도 3항목 → 4.6 '나' | `selfEval` |
| **R1** 상세 리포트 | 6대 테스트 상태 + 질문별 분석 + 근거 영상 | `detailReport` (V2 후 잠금해제) |

★ = Part 2 의 `InterviewSessionFeature ★` 에 대응하는 **엔지니어링 리스크 집중점** (AVPlayer 시간축 ↔ TCA 단방향).

## 1. 모듈 의존 그래프 (기존 그래프에 추가되는 부분)

```
AppFeature  (코디네이터: Session 종료 → Report present / Report → 친구 피드백 핸드오프)
└── InterviewReportFeature ┬ ScoringClientInterface    (리포트 폴링·fetch + 회차 기준선)
    (R0 root + 복기 Path)   ├ PlaybackClientInterface   (영상 자산·챕터·대본 cue + 재생 시간축)  ★
                           ├ ReviewClientInterface     (자기평가·👍/👎 영구 저장 → 4.6 '나')
                           └ Models · DesignSystemKit

   Path: reviewChapters(V0) → reviewPlayer(V1)★ → selfEval(V2) → detailReport(R1)
                                                       └ V2 제출 전엔 R1 push 불가 (잠금 게이트)
```

단방향 DAG. `Report` 는 `Session`/`Setup` 을 **import 하지 않는다**. "글만 보기 모드 없음"(정책 4.4·6) → R1 의 [근거 보기]도 V1 push 로만, 별도 글 진입 경로를 Path 에 만들지 않는다.

## 2. Cross-feature 라우팅 (delegate → AppFeature)

```
Session --delegate(.finished(result))------▶ AppFeature --dismiss + present--▶ Report(sessionId)
Report  --delegate(.requestFriendFeedback)-▶ AppFeature --▶ (4.5 친구 피드백 — 후속 도메인)
Report  --delegate(.retry)-----------------▶ AppFeature --▶ Setup (다음 면접)
Report  --delegate(.close)-----------------▶ AppFeature --dismiss
```

→ `@lat`: [[app#Cross-feature Routing]] · import 에 안 보이는 의존이므로 변경 시 이 표 기준으로 영향 추적.
**평가 독립성(정책 7)**: 4.5 로 넘기는 payload 는 **챕터 경계만**. 내 👍/👎·AI 지적·자기평가는 제외 → AppFeature 핸드오프에서 축소 DTO 로만 전달(§8).

## 3. Client 설계 ([[clients]] — 외부 IO 만, 유일하게 Interface/Live 분리)

| Client | 상태 | 책임 | 핵심 시그니처(요지) |
|---|---|---|---|
| **ScoringClient** | 확장 | 채점 폴링 + 사용자 리포트 fetch + 회차 기준선 | `status(sessionId)→ReportStatus` (폴링) · `report(sessionId)→InterviewReport` · `baseline(lineageId)→ReportBaseline?` |
| **PlaybackClient** | 신규 | 영상 자산·챕터·대본 cue + 재생 시간축 | `recording(sessionId)→ReviewRecording?` · `time()→AsyncStream<TimeInterval>` · `seek(to:)` · `play()`/`pause()` |
| **ReviewClient** | 신규 | 자기평가·표시 영구 저장 (4.6 '나' 재료) | `saveMarker(sessionId, ReviewMarker)` · `saveSelfEvaluation(sessionId, SelfEvaluation)` · `selfEvaluation(sessionId)→SelfEvaluation?` |

규칙: 각 Client 는 `Project.client(name:)`, `testValue` 전부 `unimplemented`(빈 클로저 금지).
**내부 채점(루브릭)→사용자 리포트 변환은 서버 책임.** 클라는 이미 변환된 `InterviewReport` 만 받는다 → 점수/판정/천장은 *애초에 클라로 안 내려온다*(§5).

## 4. 도메인 모델 (Shared/Models 추가분)

```swift
enum InterviewTest { case depth, scopeScale, connection, alternativesPriority, conflict, growthResilience }  // 6대 테스트
enum TestStatus { case confirmedStrength, needsImprovement, needsMoreEvidence }  // 3단계(확인된 강점/보완 영역/더 확인 필요)
struct TestResult { let test: InterviewTest; let status: TestStatus; let summary: String }                   // 숫자 없음

struct QuestionAnalysis: Identifiable {                                          // R1 질문 카드
    let id; let intent: String; let myAnswerSummary: String
    let goodPoints: [String]; let couldSayMore: [String]
    let relatedTest: InterviewTest; let evidenceAt: TimeInterval                 // 영상 장면 연결(필수)
}
struct RedFlagNote { let kind: RedFlagKind; let message: String; let evidenceAt: TimeInterval? }  // 부드럽게 바꾼 문구
enum RedFlagKind { case fabrication, flawlessNarrative }                         // 책임전가는 AI 안 다룸→친구(4.5)
struct SpeakingMetrics { let wordsPerMinute: Double; let fillerCount: Int; let silenceRatio: Double }  // 참고, 판정 없음

enum ReportShape { case mixed, allStrong, allWeak, insufficient, severeRedFlag } // R0 정상/예외
enum ReportStatus { case scoring, ready, insufficient }                          // 폴링: 로딩/정상/분석부족
struct InterviewReport: Identifiable {                                           // ⚠️ 점수·판정·천장 필드 없음 = 정책을 타입으로 강제
    let id: InterviewSession.ID; let shape: ReportShape
    let strength: TestResult; let improvement: TestResult; let nextReverify: [InterviewTest]  // 1~2
    let tests: [TestResult]; let questions: [QuestionAnalysis]
    let redFlags: [RedFlagNote]; let metrics: SpeakingMetrics
    let sttLossWarning: Bool                                                      // STT 30% 미만 손실 고지(논의 H)
}
struct ReportBaseline { let lineageId; let strength; let improvement; let metrics }  // 최초 4.3, 회차 비교(영상 만료돼도 유지)

// 영상 복기
struct ReviewRecording { let videoURL: URL; let chapters: [ReviewChapter]; let cues: [TranscriptCue]; let expiresAt: Date }
struct ReviewChapter: Identifiable { let id; let questionIndex: Int; let intentLabel: String; let start; let duration; let isHighlight: Bool }
struct TranscriptCue: Identifiable { let id; let start; let end: TimeInterval; let text: String; let lowConfidence: Bool }  // 약한 구간 표시만
enum MarkerKind { case questionBoundary, longSilence, aiNote, thumbUp, thumbDown }                 // 타임라인 마커
struct ReviewMarker: Identifiable { let id; let at: TimeInterval; let kind: MarkerKind; var memo: String? }  // 👍/👎(메모 선택)
struct SelfEvaluation { let didWell: String; let regret: String; let nextTry: String; let markers: [ReviewMarker] }  // V2 → 4.6 '나'
```
모듈 경계 넘는 타입은 전부 `public`(+`init`), `Equatable`/`Sendable`/`Codable` 기본.

## 5. 핵심 로직: 내부 채점 → 사용자 리포트 (정책의 코드화)

| 내부(루브릭) | 사용자에게 | 코드 위치 |
|---|---|---|
| 테스트별 1~4점 | 3단계 `TestStatus` + 설명 | 서버 변환 → `TestResult` |
| 종합점수·판정(Hire/No)·천장 | **안 내려옴** | `InterviewReport` 에 필드 자체 없음 |
| 확신 낮음 | "더 확인 필요"(약점 아님, 근거 부족) | `TestStatus.needsMoreEvidence` |
| 레드플래그 원문 | 부드러운 문구(비난 금지) | `RedFlagNote.message`(서버 변환) |
| 답변 원문+시점 | "근거 보기"→영상 장면 | `evidenceAt` → V1 `seek` |

- **강점/개선점 선정은 서버**: 6대 테스트 중 *상대 순위* + 직무·연차 가중치(절대 기준이면 빈칸 생김). 클라는 `report.strength`/`improvement` 그대로 표시.
- **R0 shape 분기**(서버가 `shape` 결정, 클라는 표현만):

```
.mixed        강점1 + 개선점1 + 다음 재검증 영역
.allStrong    개선점 → "다음 도전 영역"
.allWeak      강점 → "가장 가능성을 보인 부분"(격려 톤)
.insufficient 강점/개선점 대신 "분석할 만큼 답변이 안 모였어요" + 재도전 안내   ← ⚠️ 세션 무효(리포트 없음)와 다름
.severeRedFlag 강점 앞에 중립 안내 우선
```
⚠️ **`.insufficient`(정상이지만 얇음) ≠ 세션 무효**(중도종료·STT 30%↑ → 리포트 자체 없음, Part2 P4). 후자는 **R0 에 도달하지 않는다** → AppFeature 가 Session 종료 결과로 분기, Report 진입 자체를 막음.

## 6. `InterviewReportFeature` 구조

R0 는 root, 복기는 도메인 내부 navigation → 규칙대로 자체 `Path` + `StackState`.

```swift
@ObservableState struct State {
    let sessionId: InterviewSession.ID
    var loading: ReportStatus = .scoring   // 진입 시 채점 폴링(몇 분, 24h 내) — 로딩 중 면접 철학 콘텐츠
    var report: InterviewReport?           // .ready 에서 채워짐
    var selfEval: SelfEvaluation?          // V2 제출 후 — R1 잠금 게이트
    var path = StackState<Path.State>()    // reviewChapters → reviewPlayer → selfEval → detailReport
}
enum Action {
    case onAppear                          // ScoringClient.status 폴링 시작
    case statusUpdated(ReportStatus)
    case path(StackActionOf<Path>)
    case delegate(Delegate)
    enum Delegate { case requestFriendFeedback(InterviewSession.ID); case retry; case close }
}
```

- **채점 폴링**: `onAppear` → `clock` 으로 `status(sessionId)` 폴링 → `.ready` 면 `report(sessionId)` fetch, `.insufficient` 면 R0 격려 분기. `CancelID.statusPoll`.
- **R1 잠금 게이트(순서 의도)**: `path` 가 `.detailReport` 를 push 하려면 `selfEval != nil`. V2 의 `selfEval(SelfEvaluation)` delegate 수신 → `state.selfEval` 채우고 → `ReviewClient.saveSelfEvaluation` + R1 push 허용. (잠금 강도는 사용성 테스트로 조정 — 기획 §1.)

## 7. V1 ★ — 영상 + 대본 + 타임라인 단일 시간축 (핵심 난이도)

Part 2 Session 이 "겹치는 타이머 + 오디오 스트림"이었다면, **Part 3 는 AVPlayer(명령형 reference) ↔ TCA(값·단방향) 경계**가 리스크. 정석 레시피는 Part 2 와 동형:

- **시간축 단일 소스 = `PlaybackClient.time()` 스트림.** Live 가 AVPlayer 를 소유, reducer 는 `currentTime` 만 받아 → ① 현재 `TranscriptCue` 강조 ② chapter 경계 판정 ③ marker 배치. AVPlayer 를 State 에 두지 않는다.
- **모든 AI 근거 = `evidenceAt` 기반 `TimelineMarker`** (질문 경계·긴 침묵·AI 지적·내 👍/👎). 탭 → `seek(to:)`. "근거 보기"(R1)도 같은 경로.
- **scroll-follow 게이트**: `var followsPlayback: Bool`. 자동 스크롤 중 사용자가 직접 스크롤 → `false` + "현재 위치로" 버튼 → 다시 `true`.
- **STT 약한 구간**: `cue.lowConfidence` → 표시만, 수정 불가(정책 — 받아쓴 대본은 '보조').
- **취소 가능 effect**: `enum CancelID { case statusPoll, time }`. `@Dependency(\.continuousClock)` + `\.playbackClient`.
- **테스트**: mock `PlaybackClient`(스크립트 `time` 스트림) + `TestClock` 로 cue 강조·marker·chapter 전이를 디바이스 없이 결정론 검증. AVPlayer 의존은 Example 앱·디바이스로 격리.

## 8. 데이터 보관 · 회차 기준선 · 평가 독립성

- **영구 vs 단기**(정책): `InterviewReport`·대본 cue·`SelfEvaluation` = **영구**, 원본 영상 = **단기**(24h/7/30 논의 I). → `ReviewRecording.expiresAt`. V0 24h 임박 경고, 만료 시 V0 빈값(복기 불가)이지만 리포트·자기평가는 남는다.
- **회차 기준선**: 최초 리포트(4.3)를 `ReportBaseline` 으로 저장 → 다음 회차부터 R0·R1 에 "지난 회차 대비" 한 줄. **비교는 영상이 아니라 리포트·대본·자기평가 데이터에 의존**(영상 만료돼도 비교 유지) → baseline 에 영상 참조를 넣지 않는다.
- **평가 독립성(정책 7)**: 내 표시·AI 지적·자기평가는 본인만. 4.5 친구 payload = **챕터 경계만**. → AppFeature 가 `requestFriendFeedback` 핸드오프 시 `ReviewRecording.chapters` 중 경계 정보만 담은 축소 DTO 를 만든다(실수로 전체를 넘기면 독립성 붕괴 = load-bearing).

## 9. 기획서 "논의할 문제" → 아키텍처 영향도

빌드 전 **반드시 잠가야 하는(load-bearing)** 것:

| 항목 | 영향 | 잠그는 시점 |
| --- | --- | --- |
| **내부채점→사용자리포트 변환 위치 = 서버** (점수/판정/천장 클라 비노출) | `InterviewReport` 모델에 점수 필드 없음 = 정책을 타입으로 강제 | 🔴 Report 모델 확정 전 |
| **D** 분석부족 기준 N + `ReportStatus` 판정 위치 | 폴링 계약 `.insufficient` / R0 분기 | 🔴 ScoringClient 인터페이스 |
| **V1 재생 제어 위치** (PlaybackClient 스트림 vs View AVPlayer) | V1 reducer 테스트 가능성 (§7) | 🔴 V1 착수 전 |
| **C** 평가 독립성 payload 스코핑 | 4.5 핸드오프 축소 DTO | 🔴 친구 플로우 착수 전 |
| **evidence_timestamp 정합** (리포트↔영상↔cue 시간축 동기) | 모든 "근거 보기"·마커 동작 | 🔴 모델·Client 동시 |
| **E** "잘한 장면" 선정(서버 vs 클라 합성)·개수 | `ReviewChapter.isHighlight` 소유 주체 | 🟠 |
| **H** STT 30%↓ 손실 고지·분석 제외 | `report.sttLossWarning` + `cue.lowConfidence` | 🟠 |
| **I** 영상 보관기간 차등 + 삭제 보류 | `expiresAt` + 삭제 정책(법무) | 🟠 4.7 연동 |
| **J** 회차 "지난 대비" 비교 범위 | `ReportBaseline` 모델 | 🟡 |
| **A/B** 사용자 문구(3단계 상태/R0 이름) | 표시 문자열·로컬라이즈·DSKit | 🟡 State 자리만 |
| **F/G** 대본·타임라인 모바일 UI(탭 단위·마커 묶기) | V0/V1 View | 🟡 디자인 |

## 10. 빌드 순서 (CLAUDE.md "새 모듈 추가 흐름"에 정렬)

1. **Models 확장 + DSKit** — 위 Report/Review 타입 + 복기 전용 컴포넌트(`TestStatusChip` 3단계 · `ReviewChapterCard` · `TimelineMarkerBar` · `ThumbToggle` 👍/👎 · 참고 데이터 카드)
2. **Clients = Interface 먼저**(Live stub) — ScoringClient 확장(status/report/baseline) · PlaybackClient · ReviewClient, `testValue` 전부 unimplemented
3. **InterviewReportFeature R0 + 폴링** — `TestClock` 로 `scoring → ready/insufficient` 전이 결정론 검증
4. **V1 ★** — mock PlaybackClient(스크립트 `time` 스트림) + `TestClock` 로 cue/marker/chapter·scroll-follow 검증. Example 앱 격리, AVPlayer 는 Live 만
5. **R0 / V0 / V2 / R1 + Path** — R1 잠금 게이트 (selfEval 의존)
6. **AppFeature 배선** — `Session.finished → present Report` · `Report.requestFriendFeedback → (4.5 후속)` · 세션 무효는 Report 진입 차단
7. **회차 비교(baseline) · 4.6 종합** — 후속

## 11. 미정/후속

- **4.5 친구 피드백**(2명) — 별도 Feature, 독립성 축소-payload 계약(§8) 확정 후
- **4.6 나·AI·친구 종합 보고서** — `SelfEvaluation`('나') + AI + 친구 합성
- **4.7 영상 보관·삭제 정책** — 논의 I (PM/법무)
- A/B/C 사용자 문구 확정 → 로컬라이즈 키. 탭 IA(기록/복기 위치)는 [[domain.map]] 갱신 시
