//
//  InterviewReadinessFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/27.
//

import AVFoundation
import ComposableArchitecture
import DomainInterviewInterface
import DomainPermissionInterface
import DomainRecordingInterface
import Testing

@testable import FeatureInterviewImplementation

// 권한 게이트(진입 시 요청 → 미허용이면 곧바로 설정 유도 alert + 시작 버튼 비활성)와 phase 자동 진행을 고정한다.
@MainActor
struct InterviewReadinessFeatureTests {
    /// 스텁 편의 — 기본값은 전부 허용.
    private func client(
        status: @escaping @Sendable (MediaPermission) -> PermissionStatus = { _ in .granted },
        request: @escaping @Sendable (MediaPermission) async -> Bool = { _ in true },
        openSettings: @escaping @Sendable () async -> Void = {}
    ) -> PermissionClient {
        PermissionClient(status: status, request: request, openSettings: openSettings)
    }

    /// sessionStatus 스텁 — 기본값은 즉시 READY(요약 질문 동봉 — 페이로드 없는 READY 는 해소되지 않는다).
    private func interviewClient(
        status: @escaping @Sendable (Int) async throws -> InterviewReadiness = { _ in .ready }
    ) -> InterviewClient {
        var client = InterviewClient.testValue
        client.sessionStatus = { id in
            let readiness = try await status(id)
            return InterviewSessionStatus(
                status: readiness,
                startedAt: nil,
                summaryQuestion: readiness == .ready ? .fixture : nil
            )
        }
        return client
    }

    /// guide2(시작 버튼 활성) + 권한 허용 + 질문 준비 완료 상태 — 시작 탭 게이트 테스트 공통 시작점.
    private func guide2State() -> InterviewReadinessFeature.State {
        var state = InterviewReadinessFeature.State(sessionId: 1)
        state.phase = .guide2
        state.hasStarted = true
        state.isMediaPermissionGranted = true
        state.questionPrep = .ready(.fixture)
        return state
    }

    @Test("진입하면 준비 phase 가 자동 진행된다 — 권한 상태와 무관")
    func phasesAdvanceOnAppear() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            // 거부 상태여도 가이드 진행 자체는 막지 않는다(막는 건 시작 버튼). 프리뷰는 nil 해소.
            $0.permissionClient = client(status: { _ in .denied })
            $0.interviewClient = interviewClient()
        }
        store.exhaustivity = .off   // questionPrep·preview 해소 순서는 비결정 — phase 진행만 고정한다.

        await store.send(.view(.onAppear))
        await clock.advance(by: InterviewReadinessFeature.aligningHold)
        await store.skipReceivedActions()
        #expect(store.state.phase == .ready)
        await clock.advance(by: InterviewReadinessFeature.readyHold)
        await store.skipReceivedActions()
        #expect(store.state.phase == .guide1)
        await clock.advance(by: InterviewReadinessFeature.guide1Hold)
        await store.skipReceivedActions()
        #expect(store.state.phase == .guide2)
        await store.finish()
    }

    @Test("최소 유지 시간이 지나도 프리뷰가 해소되기 전엔 aligning 에 머문다")
    func aligningWaitsForPreview() async {
        let clock = TestClock()
        let cameraStatus = LockIsolated(PermissionStatus.notDetermined)
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient = interviewClient()
            $0.permissionClient = client(
                status: { _ in cameraStatus.value },
                request: { _ in
                    // 프리뷰 해소가 늦는 상황 재현 — 권한 다이얼로그가 10초 뒤에 허용된다.
                    try? await clock.sleep(for: .seconds(10))
                    cameraStatus.setValue(.granted)
                    return true
                }
            )
            $0.recordingClient.startPreview = { CameraPreviewHandle(session: AVCaptureSession()) }
        }
        store.exhaustivity = .off   // questionPrep 해소 등 병행 신호는 다른 테스트가 고정.

        await store.send(.view(.onAppear))
        await clock.advance(by: InterviewReadinessFeature.aligningHold)
        await store.skipReceivedActions()
        #expect(store.state.phase == .aligning)   // 타이머만으론 진행하지 않는다.

        // 권한 다이얼로그 해소(t=10s)까지 남은 만큼만 — 더 흘리면 readyHold 까지 소진돼 guide1 로 넘어간다.
        await clock.advance(by: .seconds(10) - InterviewReadinessFeature.aligningHold)
        await store.skipReceivedActions()
        #expect(store.state.phase == .ready)
        #expect(store.state.previewHandle != nil)

        // 잔여 phase 타이머(readyHold·guide1Hold)를 소진해야 finish 가 통과한다.
        await clock.advance(by: InterviewReadinessFeature.readyHold + InterviewReadinessFeature.guide1Hold)
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test("프리뷰 시작 실패(장치 없음 등)여도 placeholder 로 phase 는 진행된다")
    func previewFailureStillAdvances() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.permissionClient = client()   // 전부 허용
            $0.interviewClient = interviewClient()
            $0.recordingClient.startPreview = { nil }   // 시뮬레이터·구성 실패
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await clock.advance(by: InterviewReadinessFeature.aligningHold)
        await store.skipReceivedActions()
        #expect(store.state.phase == .ready)
        #expect(store.state.previewHandle == nil)

        // 잔여 phase 타이머(readyHold·guide1Hold)를 소진해야 finish 가 통과한다.
        await clock.advance(by: InterviewReadinessFeature.readyHold + InterviewReadinessFeature.guide1Hold)
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test("진입 시 미결정 권한은 둘 다 끝까지 요청하고, 거부되면 곧바로 설정 유도 alert 를 띄운다")
    func entryRequestsAllNotDetermined() async {
        let clock = TestClock()
        let requested = LockIsolated<[MediaPermission]>([])
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient = interviewClient()
            $0.permissionClient = client(
                status: { _ in .notDetermined },
                request: { permission in
                    requested.withValue { $0.append(permission) }
                    return false   // 둘 다 거부 — 그래도 나머지 요청 계속(설정 토글 노출)
                }
            )
        }
        store.exhaustivity = .off   // phase 진행은 위 테스트가 고정 — 여기선 요청·진입 알림만 본다.

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(8))   // 3+2+3 — 타이머 소진
        await store.skipReceivedActions()
        #expect(requested.value == [.camera, .microphone])
        #expect(!store.state.isMediaPermissionGranted)   // 시작 버튼은 비활성
        #expect(store.state.alert == InterviewReadinessFeature.permissionDeniedAlert())
        await store.finish()
    }

    @Test("카메라·마이크 중 하나만 미허용이어도 진입 alert 를 띄운다")
    func entryAlertsWhenSinglePermissionDenied() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient = interviewClient()
            $0.permissionClient = client(status: { $0 == .microphone ? .denied : .granted })
            $0.recordingClient.startPreview = { nil }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(!store.state.isMediaPermissionGranted)
        #expect(store.state.alert == InterviewReadinessFeature.permissionDeniedAlert())

        await clock.advance(by: .seconds(8))   // 잔여 phase 타이머 소진
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test("권한이 모두 허용되면 진입 alert 없이 시작 게이트가 열린다")
    func entryGrantsOpenStartGate() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.interviewClient = interviewClient()
            $0.permissionClient = client()
            $0.recordingClient.startPreview = { nil }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(store.state.isMediaPermissionGranted)
        #expect(store.state.alert == nil)

        await clock.advance(by: .seconds(8))
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test("권한이 모두 허용된 상태에서 시작하기를 누르면 세션 시작을 통보한다")
    func startTapGrantedNotifiesDelegate() async {
        let store = TestStore(initialState: guide2State()) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.permissionClient = client()
        }

        await store.send(.view(.userTappedStart))
        await store.receive(\.delegate.startRequested)
        await store.finish()
    }

    @Test("뒤로가기는 되묻는 모달 없이 곧장 이탈을 통보한다 — 아직 면접 전이라 확인 대상이 없다")
    func backTapNotifiesDelegateImmediately() async {
        let store = TestStore(initialState: guide2State()) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.permissionClient = client()
        }

        await store.send(.view(.userTappedBack))
        await store.receive(\.delegate.backRequested)
        // alert 를 띄우지 않는다 — 상태 변화 없이 통보만 하고 끝난다.
        await store.finish()
    }

    @Test("권한이 미허용이면 시작하기가 통하지 않는다 — 알림은 진입 alert 가 이미 했다")
    func startBlockedWhilePermissionDenied() async {
        var state = guide2State()
        state.isMediaPermissionGranted = false
        let store = TestStore(initialState: state) {
            InterviewReadinessFeature()
        }

        await store.send(.view(.userTappedStart))   // 상태 무변화·delegate 없음
        await store.finish()
    }

    @Test("질문 준비가 안 끝났으면 guide2 에서도 시작하기가 통하지 않는다")
    func startBlockedWhileQuestionPreparing() async {
        var state = guide2State()
        state.questionPrep = .preparing
        let store = TestStore(initialState: state) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.permissionClient = client()
        }

        await store.send(.view(.userTappedStart))   // 상태 무변화·delegate 없음
        await store.finish()
    }

    @Test("PROCESSING 폴링이 READY 로 풀리면 시작이 열린다")
    func pollingResolvesToReady() async {
        let clock = TestClock()
        let callCount = LockIsolated(0)
        var state = InterviewReadinessFeature.State(sessionId: 1)
        state.phase = .guide2
        let store = TestStore(initialState: state) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.permissionClient = client()
            $0.interviewClient = interviewClient(status: { _ in
                callCount.withValue { $0 += 1 }
                return callCount.value == 1 ? .processing : .ready
            })
            $0.recordingClient.startPreview = { nil }
        }
        store.exhaustivity = .off   // phase 타이머는 위 테스트가 고정 — 여기선 폴링 해소만 본다.

        await store.send(.view(.onAppear))
        await clock.advance(by: InterviewReadinessFeature.prepPollInterval)
        await store.skipReceivedActions()
        #expect(store.state.questionPrep == .ready(.fixture))   // 요약 질문 페이로드까지 보존된다
        await store.finish()
    }

    @Test("READY 인데 요약 질문이 없으면 해소하지 않고 다음 틱 폴링을 계속한다")
    func readyWithoutSummaryQuestionKeepsPolling() async {
        let clock = TestClock()
        let callCount = LockIsolated(0)
        var state = InterviewReadinessFeature.State(sessionId: 1)
        state.phase = .guide2
        var stubClient = InterviewClient.testValue
        stubClient.sessionStatus = { _ in
            let count = callCount.withValue { $0 += 1; return $0 }
            // 첫 응답은 계약 위반(READY + 요약 질문 없음) — 해소로 치지 않고 다음 틱이 정상 READY 를 준다.
            return InterviewSessionStatus(
                status: .ready,
                startedAt: nil,
                summaryQuestion: count == 1 ? nil : .fixture
            )
        }
        let store = TestStore(initialState: state) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.permissionClient = client()
            $0.interviewClient = stubClient
            $0.recordingClient.startPreview = { nil }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await store.skipReceivedActions()
        #expect(!store.state.isQuestionPrepReady)   // 첫 READY 는 페이로드가 없어 무시됐다

        await clock.advance(by: InterviewReadinessFeature.prepPollInterval)
        await store.skipReceivedActions()
        #expect(store.state.questionPrep == .ready(.fixture))
        await store.finish()
    }

    @Test("질문 준비 FAILED 는 실패 화면 전환을 통보한다 — 재시도 버튼 없음(PRD §3.2)")
    func questionPrepFailureNotifies() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewReadinessFeature.State(sessionId: 1)) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.permissionClient = client()
            $0.interviewClient = interviewClient(status: { _ in .failed })
            $0.recordingClient.startPreview = { nil }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        await store.receive(\.delegate.prepFailed)
        await clock.advance(by: .seconds(8))   // phase 타이머 소진
        await store.finish()
    }

    @Test("alert 닫기는 alert 만 닫고 화면에 머무른다 — 시작 버튼은 계속 비활성")
    func closeFromAlertStays() async {
        var state = guide2State()
        state.alert = InterviewReadinessFeature.permissionDeniedAlert()
        let store = TestStore(initialState: state) {
            InterviewReadinessFeature()
        }

        await store.send(.alert(.presented(.close))) {
            $0.alert = nil
        }
        await store.finish()
    }

    @Test("alert 설정으로 이동은 설정 열기를 호출한다")
    func openSettingsFromAlert() async {
        let opened = LockIsolated(false)
        var state = guide2State()
        state.alert = InterviewReadinessFeature.permissionDeniedAlert()
        let store = TestStore(initialState: state) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.permissionClient = client(openSettings: { opened.setValue(true) })
        }

        await store.send(.alert(.presented(.openSettings))) {
            $0.alert = nil
        }
        await store.finish()
        #expect(opened.value)
    }
}

private extension SummaryQuestion {
    /// READY 폴링 페이로드 픽스처 — 세션 시드 검증과 공유하는 최소 형태(turnLevel=0).
    static let fixture = SummaryQuestion(
        questionId: 1, ttsAudio: nil, turn: TurnInfo(turnLevel: 0, depthLevel: 0)
    )
}
