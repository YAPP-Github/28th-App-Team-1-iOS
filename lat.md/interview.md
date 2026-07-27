# Interview 도메인

AI 면접 연습의 중심 도메인. `DomainInterview` 가 D14 면접 세션 API([[api#Interview]])의 모델과 Repository 계약(`InterviewClient`)을 보유하고, Part 2 화면군은 `FeatureInterview` 가 구현한다([[interview#면접 흐름]]). 소비 Feature 는 `.domain(interface: .interview)` 로 연결된다.

## Client 계약
`InterviewClient` 는 Feature 가 Interview 데이터에 접근하는 유일한 통로 — `createSession`(생성)·`sessionStatus`(준비 폴링)·`submitAnswer`(답변 제출)·`questionAudioStream`(질문 TTS 재생 정보).

Interface 에 계약 + `testValue`(unimplemented) + `previewValue`(샘플), Implementation 에 `liveValue` — 구현은 App/Example 만 link 한다(D4).

- 입력 모델 `InterviewConfig` 는 Setup 위저드 산출물 — jdUrl/jdText 상호 배타는 `JobDescriptionInput` enum 으로 타입에 새겼다.
- `questionAudioStream` 은 Data 가 아니라 `InterviewAudioStream(url·headers)` 를 준다 — chunked TTS 를 AVPlayer 로 점진 재생해야 해서다([[api#Interview]] 스트리밍 규약).
- 에러는 `InterviewError`(도메인) 로 노출한다 — liveValue 가 Core `ServerError` 코드를 전용 케이스(`.freeTextNotRelevant`·`.noRemainingTicket`·`.answerAlreadySubmitted` 등, 전체 표는 [[api#Interview]])로 매핑하고, 입력 검증군은 `.invalid(message)`, 미승격 코드는 `.server(code,message)` 로 동봉해 Feature 가 Core 를 모르고도(레이어) 코드별 분기한다. 온보딩 분석 스텝이 `.freeTextNotRelevant` 를 잡아 집중 프로젝트로 되돌린다 → [[onboarding#분석]].

## API
서버 계약이 바뀌면 이 섹션·[[api#Interview]]·`liveValue` 를 함께 갱신한다. 인프라는 [[domain.map#네트워킹 인프라]] 의 `AuthorizedNetworkClient` 계약만 사용 — Bearer 첨부·토큰 재발급은 인프라 몫이고 liveValue 는 경로 조립·인코딩·디코딩만 한다.

- 세션 준비는 서버 비동기: POST(202) → 3~5초 status 폴링 → READY 에 `startedAt` + 요약 질문(base64 TTS). FAILED 는 이용권 자동 환불.
- `submitAnswer` 는 현재 turnLevel=0(첫 턴) 전용 — 서버가 일반 턴을 여는 시점에 확장한다. 메타데이터는 query, 오디오(mp3)만 multipart.
- liveValue 는 URLSession·토큰을 모르므로 테스트도 Core 구현 없이 AuthorizedNetworkClient 스텁으로 검증한다 (`InterviewClientLiveTests`).

## 면접 흐름

Part 2 «10분 음성 면접» 화면군 (`FeatureInterview`, Figma «[2] Interview_*» 프레임). 준비 → 세션 → 실패/종료의 단일 흐름이며 화면 전환은 전부 [[interview#코디네이터]] 담당. 설계 근거·남은 배선(TTS/STT·권한·녹화)은 [ai-interview](../docs/work/ai-interview.md) §6.

현재는 화면 상태머신까지 구현된 상태 — 카메라 프리뷰는 placeholder(`InterviewCameraBackdrop` seam), 음성 입출력은 inner 액션 seam 만 있다.

## 코디네이터

`InterviewFeature` 가 흐름 루트 — screen enum destination(준비/세션/실패)을 전면 교체한다. push 스택이 없어 StackState 대신 `@Reducer enum`. 하위 화면의 delegate 만 매칭하고, 흐름 밖(보고서 진입·닫기)은 delegate(.finished/.closed)로 AppFeature 에 올린다.

- AppFeature 배선(세션 payload — 온보딩 산출 sessionId 수신 포함)은 미착수 → [ai-interview](../docs/work/ai-interview.md) §2.

## 권한

`DomainPermission` — 카메라·마이크 권한의 유일한 통로 `PermissionClient`(`status(MediaPermission)`·`request`·`openSettings`). iOS 는 사용 시점 요청(PRD §8) 원칙이라 소비처는 면접 준비 화면([[interview#준비]])뿐.

서버 API 가 아닌 디바이스 IO. Interface 에 계약+testValue(unimplemented)+previewValue(전부 granted), Implementation 에 AVFoundation liveValue — App/Example 만 link (D4).

- restricted 는 denied 로 접는다 — 사용자가 못 푸는 상태여도 앱 대응은 "설정 안내"로 동일.
- 마이크도 `AVCaptureDevice(.audio)` 축 — 영상+음성 캡처 세션 기준.
- `openSettings` 를 Client 에 둔 이유: View 의 `openURL` 로 하면 리듀서 테스트로 검증 불가.

## 준비

`InterviewReadinessFeature` — 카메라 확인+안내를 한 화면 4단계 phase(aligning → ready → guide1 → guide2)로 전환. 진입 시 카메라·마이크 권한을 요청만 하고([[interview#권한]]) 거부여도 가이드는 조용히 진행 — 게이트는 «면접 시작하기» 탭. 허용 확인 후에만 delegate(.startRequested).

Figma 2479:7569 · 2514:12754 · 2514:12799 · 2529:458.

- 시작하기 탭에 권한 미허용 → 설정 유도 alert: [설정으로 이동]=`openSettings` / [닫기]=alert 만 닫고 화면 유지 — 시작 버튼 재탭이 재시도 지점(막다른 길 없음). 설정에서 권한을 바꾸면 iOS 가 앱을 종료시켜 onAppear 부터 재진입하므로 별도 복귀 재확인은 두지 않는다. 탭 시점엔 권한이 전부 결정된 상태(진입 다이얼로그가 모달)라 status 동기 확인으로 판정한다.
- phase 자동 진행은 시간 연출(tentative) — RecordingClient(프리뷰) 도입 시 aligning→ready 를 실제 카메라 준비 신호로 교체.
- 브래킷 프레임(`CameraGuideFrame`)·하단 티커는 에셋 없이 코드 드로잉 — Figma color-burn 블렌드는 카메라 배선 시 재검토.

## 세션

`InterviewSessionFeature` — 단일 화면 턴 상태머신(asking/answering/finalCountdown) + 세션 시계 1초 틱. 8:00 종료 해금(토스트+«면접 종료하기») → 9:50 빨간 초읽기 → 10:00 delegate(.finished). 질문 텍스트는 View 에 노출하지 않는다(TTS-only).

Figma: 2529:6309 · 2537:9397 · 2638:1750 · 2537:9442 · 2537:9525.

- 종료 확인 모달(Figma 2555:7696)은 destination 없이 Bool 오버레이 — «마치기» 즉시 종료, 지금까지 답변으로 분석.
- asking→answering 전환(questionPlaybackFinished)·답변 제출(submitAnswer)·실패 감지(failureDetected)는 SpeechClient(예정) 배선 시 effect 로 채운다. 시계 임계(8:45 랩업·12:00 hard cap)도 그때 재검토.
- 시계 상태머신은 `InterviewSessionFeatureTests` 가 고정 (TestClock).

## 실패

`InterviewFailureFeature` — STT 인식 불가·네트워크 단절 공통 실패 화면(kind 파라미터, Figma 2550:7504 · 2638:17018). 이용권 미차감 안내(서버 자동 환불 — [[interview#API]]). X = closeRequested(흐름 이탈), 다시 시작하기 = restartRequested(준비부터 재시작).
