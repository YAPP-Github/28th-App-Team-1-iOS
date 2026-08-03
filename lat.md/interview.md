# Interview 도메인

AI 면접 연습의 중심 도메인. `DomainInterview` 가 D14 면접 세션 API([[api#Interview]])의 모델과 Repository 계약(`InterviewClient`)을 보유하고, Part 2 화면군은 `FeatureInterview` 가 구현한다([[interview#면접 흐름]]). 소비 Feature 는 `.domain(interface: .interview)` 로 연결된다.

## Client 계약
`InterviewClient` 는 Feature 가 Interview 데이터에 접근하는 유일한 통로 — `createSession`(생성)·`sessionStatus`(준비 폴링)·`submitAnswer`(답변 제출 = 턴 루프의 축)·`questionAudioStream`(질문 TTS 재생 정보)·`reportList`(내 레포트 목록).

Interface 에 계약 + `testValue`(unimplemented) + `previewValue`(샘플), Implementation 에 `liveValue` — 구현은 App/Example 만 link 한다(D4).

- 입력 모델 `InterviewConfig` 는 Setup 위저드 산출물 — jdUrl/jdText 상호 배타는 `JobDescriptionInput` enum 으로 타입에 새겼다.
- `questionAudioStream` 은 Data 가 아니라 `InterviewAudioStream(url·headers)` 를 준다 — chunked TTS 를 AVPlayer 로 점진 재생해야 해서다([[api#Interview]] 스트리밍 규약).
- 에러는 `InterviewError`(도메인) 로 노출한다 — liveValue 가 Core `ServerError` 코드를 전용 케이스(`.freeTextNotRelevant`·`.noRemainingTicket`·`.answerAlreadySubmitted` 등, 전체 표는 [[api#Interview]])로 매핑하고, 입력 검증군은 `.invalid(message)`, 미승격 코드는 `.server(code,message)` 로 동봉해 Feature 가 Core 를 모르고도(레이어) 코드별 분기한다. 온보딩 분석 스텝이 `.freeTextNotRelevant` 를 잡아 집중 프로젝트로 되돌린다 → [[onboarding#분석]].

## API
서버 계약이 바뀌면 이 섹션·[[api#Interview]]·`liveValue` 를 함께 갱신한다. 인프라는 [[domain.map#네트워킹 인프라]] 의 `AuthorizedNetworkClient` 계약만 사용 — Bearer 첨부·토큰 재발급은 인프라 몫이고 liveValue 는 경로 조립·인코딩·디코딩만 한다.

- 세션 생성은 회원 프로필 스냅샷(직군·연차 미전송 — 미등록이면 `USER_PROFILE_NOT_REGISTERED`). 준비는 서버 비동기: POST(202) → 3~5초 status 폴링 → READY 에 `startedAt` + 요약 질문(base64 TTS). FAILED 는 이용권 자동 환불.
- `submitAnswer` 응답이 턴을 결정한다 — `nextQuestion`(계속) 또는 `sessionEnded` + `SessionEndType` 5종(NORMAL/MANUAL/HARD_CAP/BACK_EXIT(구 EARLY_EXIT)/**STT_RESET** — STT 30% 판정은 서버) + 마무리 멘트(`wrapUpMessage.ttsAudio`). 메타데이터는 query(`isWrapUp` required), 오디오만 multipart. 503(`AI_TEMPORARILY_UNAVAILABLE`)은 서버에 아무것도 저장되지 않아 같은 요청 재시도 계약.
- liveValue 는 URLSession·토큰을 모르므로 테스트도 Core 구현 없이 AuthorizedNetworkClient 스텁으로 검증한다 (`InterviewClientLiveTests`).

## 면접 흐름

Part 2 «10분 음성 면접» 화면군 (`FeatureInterview`, Figma «[2] Interview_*» 프레임). 준비 → 세션 → 리포트 대기 / 실패의 단일 흐름이며 화면 전환은 전부 [[interview#코디네이터]] 담당. 설계 근거·남은 배선(TTS/STT·녹화)은 [ai-interview](../docs/work/ai-interview.md) §6.

화면·타이밍·문구는 Part 2 PRD v3 에 정합된 상태(2026-07-27) — 카메라 프리뷰는 실동작(DomainRecording, [[interview#프리뷰]]), 서버 턴 루프는 실 API(`submitAnswer` — [[interview#세션]], 2026-08-02 작업 C), 질문 TTS·마무리 멘트 재생은 [[interview#음성 캡처]]의 재생 계약. 발화 감지·침묵 판정·실녹음(작업 B)만 남았다.

## 코디네이터

`InterviewFeature` 가 흐름 루트 — screen enum destination(준비/세션/리포트 대기/실패)을 전면 교체한다. push 스택이 없어 StackState 대신 `@Reducer enum`. 하위 화면의 delegate 만 매칭하고, 흐름 밖(보고서 진입·닫기)은 delegate(.finished/.closed)로 AppFeature 에 올린다.

- `State(sessionId:)` 로 온보딩 분석이 만든 세션 id 를 들고 있다 — 준비 화면의 질문 준비 폴링과, 실패 후 «다시 시작하기» 재진입이 같은 세션을 쓴다.
- 시작 전환(startRequested)은 준비 화면의 READY 페이로드(요약 질문)와 프리뷰 핸들을 `InterviewSessionFeature.State(sessionId:summaryQuestion:previewHandle:)` 로 시드한다 — 세션이 첫 턴을 바로 재생한다.
- 알려진 제약: STT_RESET 후 «다시 시작하기» 는 같은 sessionId 로 재진입하지만 세션은 서버에서 무효화돼 거부된다 — 새 세션 생성 동선은 미해결(Example 은 부트스트랩 재실행으로 갈음).
- 세션 `finished` 는 상위로 바로 올리지 않는다 — [[interview#리포트 대기]] 를 먼저 띄우고, 거기서 온 `goHomeRequested` 만 `delegate(.finished)` 로 승격한다. 세션 `aborted`·실패 화면 `closeRequested` 는 `delegate(.closed)`.
- 준비 `prepFailed` → 실패 화면(kind: questionPrep). 실패 `restartRequested`(STT 전용) → 같은 sessionId 로 준비 화면 재진입.
- AppFeature 배선 완료(2026-08-03) — 온보딩 `finished(sessionId)` 가 `InterviewFeature.State(sessionId:)` 로 커버를 열고, 종료 두 신호는 모두 커버를 닫아 홈으로 돌린다. 목적지가 같아도 `.finished`/`.closed` 를 합치지 않는 건 홈 리포트 목록 갱신이 정상 종료에만 필요해서다 → [[app#Cross-feature Routing]].
- AppFeature 배선 완료 — 온보딩 `delegate(.finished(sessionId:))` 가 `@Presents var interview` 를 세워 `fullScreenCover` 로 연다. 흐름 밖 신호 두 개(`finished`·`closed`)는 cover 를 닫고 홈을 재조회시킨다 → [[app]]. 정상 종료 → 리포트 상세(r1)는 아직 TODO → [ai-interview](../docs/work/ai-interview.md) §2.

## 권한

`DomainPermission` — 카메라·마이크 권한의 유일한 통로 `PermissionClient`(`status(MediaPermission)`·`request`·`openSettings`). iOS 는 사용 시점 요청(PRD §8) 원칙이라 소비처는 면접 준비 화면([[interview#준비]])뿐.

서버 API 가 아닌 디바이스 IO. Interface 에 계약+testValue(unimplemented)+previewValue(전부 granted), Implementation 에 AVFoundation liveValue — App/Example 만 link (D4).

- restricted 는 denied 로 접는다 — 사용자가 못 푸는 상태여도 앱 대응은 "설정 안내"로 동일.
- 마이크도 `AVCaptureDevice(.audio)` 축 — 영상+음성 캡처 세션 기준.
- `openSettings` 를 Client 에 둔 이유: View 의 `openURL` 로 하면 리듀서 테스트로 검증 불가.

## 준비

`InterviewReadinessFeature` — 카메라 확인+안내를 한 화면 4단계 phase(aligning → ready → guide1 → guide2)로 전환. 시작 게이트는 «guide2 + 카메라·마이크 권한 + 질문 준비 READY» 삼중이고, 셋을 다 통과해야 delegate(.startRequested) 를 올린다.

Figma 2479:7569 · 2514:12754 · 2514:12799 · 2529:458.

- 진입 시 카메라·마이크 권한을 요청만 하고([[interview#권한]]) 거부여도 가이드는 조용히 진행 — 알리는 시점은 «면접 시작하기» 탭이다.
- 좌상단 뒤로가기(2026-08-03 시안, 세션 화면과 같은 DS 네비바)는 **되묻는 모달 없이 즉시** `delegate(.backRequested)` → 코디네이터가 장치 정지 후 `closed`. 아직 질문 재생 전·답변 0개라 확인할 손실이 없다 — 8:00 전 이탈 경고는 «면접 진행 중» 전용이다. 서버 세션은 남지만 재진입 동선은 홈의 «이어서 진행» 몫([home-account](../docs/work/home-account.md) §4).
- 질문 준비(preload, PRD §3.2)는 `InterviewClient.sessionStatus` 3초 폴링(온보딩 분석 스텝과 같은 주기). READY/FAILED 에서 스스로 멈추고, 그 사이 네트워크 에러는 `try?` 로 삼켜 다음 틱 재시도 — «시스템이 알아서 다시 시도» 가 폴링 지속이라 클라 타임아웃도 재시도 버튼도 없다. 최종 실패는 서버 FAILED 만 신뢰한다. READY 는 요약 질문 동봉 시에만 해소(`.ready(SummaryQuestion)` — 세션 시드용) — 페이로드 없는 READY 는 계약 위반으로 보고 폴링을 계속한다.
- 준비 중(preparing)엔 시작 버튼 비활성 — 리듀서도 `questionPrep == .ready` 를 재확인해 레이스를 무시한다. FAILED → delegate(.prepFailed) → 실패 화면(questionPrep).
- 시작하기 탭에 권한 미허용 → 설정 유도 alert: [설정으로 이동]=`openSettings` / [닫기]=alert 만 닫고 화면 유지 — 시작 버튼 재탭이 재시도 지점(막다른 길 없음). 설정에서 권한을 바꾸면 iOS 가 앱을 종료시켜 onAppear 부터 재진입하므로 별도 복귀 재확인은 두지 않는다. 탭 시점엔 권한이 전부 결정된 상태(진입 다이얼로그가 모달)라 status 동기 확인으로 판정한다.
- aligning→ready 는 «최소 유지 시간(3초) + 프리뷰 해소» 이중 게이트 — 실패(권한 거부·시뮬레이터)도 해소로 치고 placeholder 로 진행한다(화면을 막지 않음, 게이트는 시작 탭). ready 이후는 시간 연출.
- 브래킷 프레임은 DS 로 승격됐다 — `SharedDesignSystem` 의 `CameraGuideFrame`(`Interface/Component/CameraGuideFrame.swift`), 화면은 문구만 넘긴다. 이것과 하단 티커는 에셋 없이 코드 드로잉이고, 블렌드 스위치는 [[interview#프리뷰]].
- 하단 티커(문구 3연속)는 화면보다 넓어 **`overlay` 로 얹는다** — `.fixedSize().frame(maxWidth: .infinity)` 로 두면 넘친 이상적 폭이 부모로 새어 화면 좌표계가 넓어지고, 그 위 네비바가 왼쪽으로 밀려 뒤로가기가 가장자리에 붙는다(`.clipped()` 는 그림만 자를 뿐 레이아웃은 못 되돌린다). 높이·배경은 문구 «한 벌»이 잡는다. 2026-08-03 실기 확인 후 수정.

## 프리뷰

`DomainRecording`(RecordingClient) 이 단일 AVCaptureSession 을 actor 로 소유한다. startPreview 는 멱등 — 준비 화면이 켜고, 정지는 코디네이터가 카메라 화면 이탈 전환에서만 수행한다. 프리뷰 뷰(backdrop)는 화면이 아닌 `InterviewView` 에 상주해 화면 교체에도 레이어가 유지된다.

- 핸들(`CameraPreviewHandle`)은 identity-Equatable 래퍼 — TCA State 에 저장, 뷰(`InterviewCameraBackdrop`)는 핸들 유무로 실카메라/placeholder 분기.
- backdrop 을 각 화면에 두고 State 시드로 핸들만 이어줘도 전환 시 카메라가 끊겨 보인다(실기기 확인) — `AVCaptureVideoPreviewLayer` 가 화면 교체와 함께 파괴·재생성되기 때문. 그래서 backdrop 은 코디네이터 뷰 상주, 핸들·스크림·모달 배경 블러는 화면 State 에서 파생만 한다(시작 전환 핸들 시드·onAppear 재요청은 백스톱으로 유지).
- 녹화(`startRecording`/`stopRecording`)는 시그니처만 확정된 골격 — 실구현·호출처는 작업 B. liveValue 는 `RecordingError.notImplemented` 를 던진다.
- 정지 지점: 준비→실패, 세션→리포트 대기, 세션→실패, 세션 중도 이탈. 실패·이탈 전환은 재생(stopPlayback)도 함께 끊고, 리포트 대기 전환만 재생을 살린다(마무리 멘트). 재진입은 Readiness onAppear 가 다시 켠다.
- Scope-on-enum 코디네이터는 화면 교체 시 자식 effect 를 취소하지 않는다 — readiness 의 프리뷰 시작 effect 가 화면 교체를 넘겨 살아남을 수 있어, 흐름 이탈(aborted·closeRequested)은 정지 완료 후 상위 통보로 순서를 보장한다(`stopCaptureDevicesThenNotifyClosed` — 마이크 캡처도 함께 정지, [[interview#음성 캡처]]).
- 백그라운드 전환은 iOS 의 AVCaptureSession 인터럽션 자동 복구(비디오 전용 세션)에 맡긴다.
- 브래킷 프레임 Figma color-burn 블렌드는 `CameraGuideFrame(blendsColorBurn:)` 로 구현돼 있고 **기본 꺼짐** — 프리뷰가 UIKit 호스팅 레이어(`AVCaptureVideoPreviewLayer`)라 SwiftUI 블렌드가 그걸 backdrop 으로 합성하지 못한다(투명 배경에 걸려 새까매질 수 있다). 실기기 육안 확인이 끝나면 켠다.

## 음성 캡처

`DomainSpeech`(SpeechClient) 가 AVAudioEngine 마이크 캡처를 actor 로 소유한다. 세션 화면이 전구간 이벤트 스트림을 구독해 로그로 마이크 동작을 검증한다 — STT 도입 전 검증 슬라이스(설계: docs/superpowers/specs/2026-07-29-mic-capture-design.md). 정지는 세션 effect 취소 + 코디네이터 `stopCaptureDevices` 이중.

- 이벤트: `level`(1초 윈도 피크 dBFS) · `speechStarted`(−35 dBFS 상향 돌파) · `speechEnded`(−45 미만 1초 지속 — 히스테리시스) · `captureFailed`. 임계 상수는 실기기 튜닝 여지.
- STT 교체 seam: Interface 에 transcription 엔드포인트를 추가하고 Implementation 이 같은 tap 버퍼를 STT 엔진에 공급 — 소비처(세션 Reducer)는 이벤트 매칭만 확장.
- 소비처는 로그만(State 무변화, `os.Logger` category `MicCapture`) — STT 도입 시 inner 액션으로 승격.
- AVAudioSession 은 `.playAndRecord` — 추후 질문 TTS 재생과 마이크 캡처를 한 세션에서 쓴다. 카메라 AVCaptureSession(비디오 전용)과 무충돌.
- 엔진 정지는 스트림 onTermination(effect 취소 시)과 `stopCapture`(코디네이터) 양쪽에서 보장 — 둘 다 멱등.
- 재생 계약(2026-08-02): `play`(base64 mp3 — 요약 질문·마무리 멘트) · `playStream(url:headers:)`(질문 chunked TTS — `InterviewAudioStream` 을 풀어 전달해 Speech→Interview Interface 의존을 만들지 않는다) · `answerAudio`(실녹음 seam — liveValue 는 nil, Example 만 번들 샘플) · `stopPlayback`(멱등). 재생 주체는 `AudioPlaybackManager` 액터 — 소비 effect 가 취소돼도 재생은 지속(마무리 멘트 fire-and-forget 근거)하고, 정지는 이탈·실패 전환의 코디네이터 호출뿐이다.

## 세션

`InterviewSessionFeature` — 단일 화면 턴 상태머신(asking/answering/processingAnswer/finalCountdown) + 세션 시계 1초 틱. 8:00 종료 해금(토스트+«면접 종료하기») → 11:50 빨간 초읽기 → 12:00 hard cap 종료(PRD §3.6). 질문 텍스트는 View 에 노출하지 않는다(TTS-only).

Figma: 2529:6309 · 2537:9397 · 2638:1750 · 2537:9442 · 2537:9525.

- phase 4종이 상태 칩 3종(PRD §3.5)에 대응한다 — «질문 듣는 중»/«답변 녹음 중»/«답변을 정리하고 있어요», finalCountdown 은 칩 없이 빨간 초읽기. «답변이 기록 됐어요» 토스트는 칩이 역할을 대체해 소멸했고, 남은 토스트는 exitUnlocked·timeExpired 2종뿐이다.
- «답변 완료하기» 는 침묵 판정을 기다리지 않고 즉시 `processingAnswer` 로 확정하고 `submitAnswer` 를 보낸다(중복 제출 가드 `isSubmitting`, 2026-08-02 작업 C — 2초 mock 소멸). 응답 분기: `nextQuestion` → asking 복귀+재생 / `sessionEnded` → endType 별 `finished`(NORMAL·MANUAL·HARD_CAP — 마무리 멘트 fire-and-forget)·`aborted`(BACK_EXIT)·`failed(.speechRecognition)`(STT_RESET).
- 종료 경로도 제출을 경유한다 — 마치기=MANUAL_END·12:00 상한=HARD_CAP(제출 완료까지 processingAnswer 로 대기, 제출 비행 중 상한 도달은 응답 수신 후 HARD_CAP 마감). 8분 전 이탈은 BACK_EXIT 최선 노력 1회 제출(실패해도 이탈 진행). 503 은 같은 제출을 1s·3s 백오프로 최대 2회 재시도, `SESSION_ALREADY_ENDED`(409)는 리포트 대기로.
- 질문 재생: 요약 질문(턴 0)은 READY 동봉 mp3(`play`), 이후 질문은 `questionAudioStream`→`playStream`(chunked). 재생 실패는 같은 questionId 1회 재시도(TTS 재생성) 후 network 실패. 시간 마킹(questionAudioStart/End·answerStart)은 세션 시계 스냅샷 — 실녹화(작업 B) 전 근사값.
- «12분» 숫자는 어떤 화면·문구에도 노출하지 않는다(§3.10 — 사용자에겐 «약 10분»). 경과 시계는 10분을 넘어도 m:ss 로 계속 오른다.
- 좌상단은 **뒤로가기 `<`**(2026-08-03 시안 — 「Part2. 면접 녹화」 전 프레임 공통). DS `.hilitPresentedNavigationBar(surface: .dark, leading: .back)` — cover 라 present 판, 카메라 영상이 바닥이라 `.dark`(흰 글리프). 글리프만 X 에서 바뀌고 **배관은 그대로**다(아래 분기 유지). 브래킷(`CameraGuideFrame`)은 네비바 `safeAreaInset` **밖**(`.background`)에 둔다 — 안에 두면 콘텐츠가 44 밀려 327 정방형 중심이 22 내려간다. 같은 이유로 상단 칩·타이틀 offset 은 51 이 아니라 7(= Figma y94 − 바 하단 87).
- 좌상단 뒤로가기는 8:00 전이면 중도 이탈 경고(«다음에 면접을 다시 진행할까요?», Figma modal 3907:890 — 아이콘 없음, «면접 계속하기»가 강조(검정) 쪽, 차감 사실만·리포트 언급 금지), 8:00 후면 종료 확인 모달(Figma 2555:7696)로 갈린다. 둘 다 destination 없이 Bool 플래그이고 같은 모달 컴포넌트를 쓴다 — 뷰가 두 Bool 을 enum 하나로 접어 DS `.hilitModal(item:)` 로 표출한다(종료 확인 우선, 동시 true 방어). 8:00 해금 틱이 열려 있던 경고를 닫아 «경고를 띄운 채 해금» 레이스를 막는다.
- `aborted` 는 기록 폐기가 아니다 — 그때까지의 턴은 서버가 보존하고 이용권도 차감된다(PRD §3.7 D1). 클라는 이탈 신호만 올린다.
- asking→answering 은 재생 완료(questionPlaybackFinished)가 전환한다 — 배선 완료. 발화 감지·침묵 10초 확정·사고 5초는 작업 B 잔여. 랩업은 8:45 경과 시 `isWrapUp=true` 제출로 서버에 알린다(새 질문 금지는 서버 판단).
- 시계 상태머신·이탈은 `InterviewSessionFeatureTests`, 턴 루프·제출 분기는 `InterviewSessionSubmissionTests` 가 고정 (TestClock).

## 실패

`InterviewFailureFeature` — 면접 중단 안내 공통 화면. kind 3종(speechRecognition·network·questionPrep)이 배지·문구·하단 버튼만 바꾸는 같은 레이아웃이라 리듀서는 kind 파라미터 하나뿐이다(Figma 2550:7504 · 2638:17018). 이용권 미차감 안내(서버 자동 환불 — [[interview#API]])는 공통.

- 하단 버튼이 kind 별로 다르다: speechRecognition = «다시 시작하기»(restartRequested — 준비부터 재시작, PRD §3.9) / network = «홈으로» / questionPrep = «처음으로». 뒤 둘은 closeRequested 뿐 — 재시도 버튼을 주지 않는 것이 PRD 확정(§3.7·§3.2)이라 restartRequested 는 STT 전용 경로다.
- questionPrep 은 세션이 아니라 준비 화면의 폴링이 올린다([[interview#준비]]) — 질문 준비 최종 실패(서버 FAILED).
- 질문 준비 실패 화면(`Interview_QuestionPrepFailure`)은 Figma 시안 미출 — 레이아웃·배지를 network 실패에서 임시 재사용 중이라 시안 확정 시 교체한다.

## 리포트 대기

`InterviewReportPendingFeature` — 면접 정상 종료 직후의 «리포트를 만들고 있어요» 안내 화면(`Interview_ReportPending`, PRD §3.8). 버튼 하나(«홈으로» → delegate(.goHomeRequested))뿐이라 상태 없는 최소 리듀서다. 리포트 완료 폴링·재진입 표시는 Part 3/홈 몫.

- 세션이 어떻게 끝났든(마치기·12:00 상한·자연 종료) 이 화면을 거친다 — 코디네이터가 `finished` 를 여기로 받고, 여기서 온 goHomeRequested 만 상위로 승격한다([[interview#코디네이터]]).
- 금지 문구 3종(§3.8): «나가도 돼요» · «앱을 닫아도 돼요» · «완료되면 알려드려요». 푸시가 없어서 못 지킬 약속이 되기 때문 — 완료 통지 수단이 생기기 전엔 쓰지 않는다.
- 마무리 멘트(음성)는 SpeechClient 배선(작업 B) 몫. 화면 시안도 미출이라 기존 레이아웃·DS 토큰 재사용 임시본이다.
