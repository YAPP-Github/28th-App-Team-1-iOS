//
//  InterviewReadinessFeatureTests.swift
//  FeatureInterviewTests
//
//  Created by 서정원 on 26/07/27.
//

import ComposableArchitecture
import DomainPermissionInterface
import Testing

@testable import FeatureInterviewImplementation

// 권한 게이트(진입 시 요청 → 시작하기 탭에서 확인, 미허용이면 설정 유도 alert)와 phase 자동 진행을 고정한다.
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

    /// guide2(시작 버튼 활성)까지 도달한 상태 — 시작 탭 게이트 테스트 공통 시작점.
    private func guide2State() -> InterviewReadinessFeature.State {
        var state = InterviewReadinessFeature.State()
        state.phase = .guide2
        state.hasStarted = true
        return state
    }

    @Test("진입하면 준비 phase 가 자동 진행된다 — 권한 상태와 무관")
    func phasesAdvanceOnAppear() async {
        let clock = TestClock()
        let store = TestStore(initialState: InterviewReadinessFeature.State()) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            // 거부 상태여도 가이드는 진행 — 알림은 시작하기 탭 시점으로 미룬다.
            $0.permissionClient = client(status: { _ in .denied })
        }

        await store.send(.view(.onAppear)) {
            $0.hasStarted = true
        }
        await clock.advance(by: InterviewReadinessFeature.aligningHold)
        await store.receive(\.inner.phaseHoldFinished) { $0.phase = .ready }
        await clock.advance(by: InterviewReadinessFeature.readyHold)
        await store.receive(\.inner.phaseHoldFinished) { $0.phase = .guide1 }
        await clock.advance(by: InterviewReadinessFeature.guide1Hold)
        await store.receive(\.inner.phaseHoldFinished) { $0.phase = .guide2 }
        await store.finish()
    }

    @Test("진입 시 미결정 권한은 둘 다 끝까지 요청한다 — 거부돼도 alert 없이 조용히 진행")
    func entryRequestsAllNotDetermined() async {
        let clock = TestClock()
        let requested = LockIsolated<[MediaPermission]>([])
        let store = TestStore(initialState: InterviewReadinessFeature.State()) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.permissionClient = client(
                status: { _ in .notDetermined },
                request: { permission in
                    requested.withValue { $0.append(permission) }
                    return false   // 둘 다 거부 — 그래도 나머지 요청 계속(설정 토글 노출)
                }
            )
        }
        store.exhaustivity = .off   // phase 진행은 위 테스트가 고정 — 여기선 요청·무알림만 본다.

        await store.send(.view(.onAppear))
        await clock.advance(by: .seconds(8))   // 3+2+3 — 타이머 소진
        await store.finish()
        #expect(requested.value == [.camera, .microphone])
        #expect(store.state.alert == nil)
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

    @Test("권한이 미허용인 상태에서 시작하기를 누르면 설정 유도 alert 를 띄우고 시작하지 않는다")
    func startTapDeniedShowsAlert() async {
        let store = TestStore(initialState: guide2State()) {
            InterviewReadinessFeature()
        } withDependencies: {
            $0.permissionClient = client(status: { $0 == .camera ? .denied : .granted })
        }

        await store.send(.view(.userTappedStart)) {
            $0.alert = InterviewReadinessFeature.permissionDeniedAlert()
        }
        await store.finish()
    }

    @Test("alert 닫기는 alert 만 닫고 화면에 머무른다 — 재시도는 시작하기 재탭")
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
