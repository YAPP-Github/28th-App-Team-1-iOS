//
//  AuthFeatureGateTests.swift
//  FeatureAuthTests
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import DomainAuthInterface
import DomainConsentInterface
import XCTest

@testable import FeatureAuthImplementation

/// 게이트 2단 체인(동의 → 프로필)의 목적지 표 검증 — docs/work/launch-routing.md §2.
/// 로그인 경로(`authenticated`)와 세션 복구 경로(`State(resuming:)`)가 같은 목적지로 수렴하는지 본다.
final class AuthFeatureGateTests: XCTestCase {
    private static let items = [
        ConsentItem(code: "TERMS_OF_SERVICE", label: "서비스 이용약관", isRequired: true, version: 1, hasDocument: true)
    ]

    // MARK: - 로그인 경로 (게이트 판정값 = login 응답)

    /// 신규 — 동의 미제출 + 프로필 미등록. 약관부터.
    @MainActor
    func test_동의미제출_프로필미등록_약관으로() async {
        let store = makeStore()

        await store.send(.createAccount(.delegate(.authenticated(
            LoginResult(consentStatus: .notSubmitted, profileRegistered: false)
        )))) {
            $0.profileRegistered = false
            $0.path.append(.terms(AuthTermsFeature.State()))
        }
    }

    /// 재동의 — 약관 개정. 프로필이 이미 있어도 동의 게이트가 먼저다.
    @MainActor
    func test_재동의_프로필등록됨_약관먼저() async {
        let store = makeStore()

        await store.send(.createAccount(.delegate(.authenticated(
            LoginResult(consentStatus: .stale, profileRegistered: true)
        )))) {
            $0.profileRegistered = true
            $0.path.append(.terms(AuthTermsFeature.State()))
        }
    }

    /// 동의는 끝났는데 프로필 등록 전에 이탈한 사용자 — 홈 직행이 아니라 온보딩.
    @MainActor
    func test_동의최신_프로필미등록_온보딩으로() async {
        let store = makeStore()

        await store.send(.createAccount(.delegate(.authenticated(
            LoginResult(consentStatus: .upToDate, profileRegistered: false)
        )))) {
            $0.profileRegistered = false
            $0.path.append(.naming(AuthOnboardingNamingFeature.State(step: 1, totalSteps: 3)))
        }
    }

    /// 기존 회원 — 두 게이트 모두 통과. 스택을 쌓지 않고 곧장 홈.
    @MainActor
    func test_동의최신_프로필등록됨_홈직행() async {
        let store = makeStore()

        await store.send(.createAccount(.delegate(.authenticated(
            LoginResult(consentStatus: .upToDate, profileRegistered: true)
        )))) {
            $0.profileRegistered = true
        }
        await store.receive(\.delegate.signedIn)
    }

    // MARK: - 약관 통과 후 프로필 게이트

    /// 약관 제출 성공 → 프로필 미등록이면 온보딩.
    @MainActor
    func test_약관제출후_프로필미등록_온보딩으로() async {
        let store = makeStore(state: .init(resuming: .terms(items: Self.items, profileRegistered: false)))
        let termsID = store.state.path.ids[0]

        await store.send(.path(.element(id: termsID, action: .terms(.delegate(.agreed))))) {
            $0.path.append(.naming(AuthOnboardingNamingFeature.State(step: 1, totalSteps: 3)))
        }
    }

    /// 약관 제출 성공 → 프로필이 이미 있으면 홈. 온보딩을 다시 밟지 않는다.
    @MainActor
    func test_약관제출후_프로필등록됨_홈으로() async {
        let store = makeStore(state: .init(resuming: .terms(items: Self.items, profileRegistered: true)))
        let termsID = store.state.path.ids[0]

        await store.send(.path(.element(id: termsID, action: .terms(.delegate(.agreed)))))
        await store.receive(\.delegate.signedIn)
    }

    /// 약관 중도 이탈 — 계정은 남지만 미제출이라 A0 로 되돌린다.
    @MainActor
    func test_약관이탈_로그인화면복귀() async {
        let store = makeStore(state: .init(resuming: .terms(items: Self.items, profileRegistered: false)))
        let termsID = store.state.path.ids[0]

        await store.send(.path(.element(id: termsID, action: .terms(.delegate(.closeRequested))))) {
            $0.path.removeAll()
        }
    }

    // MARK: - 세션 복구 진입 (판정값 = Splash 의 pending 조회)

    /// 복구 경로는 A0 를 거치지 않는다 — 스택 첫 화면이 곧 목적지고, 조회해 둔 항목이 주입된다.
    @MainActor
    func test_세션복구_약관진입_항목주입() {
        let state = AuthFeature.State(resuming: .terms(items: Self.items, profileRegistered: true))

        XCTAssertEqual(state.path.count, 1)
        XCTAssertEqual(state.profileRegistered, true)
        guard case let .terms(terms) = state.path[0] else {
            return XCTFail("복구 진입은 약관 화면이어야 한다")
        }
        XCTAssertEqual(terms.items, Self.items)
    }

    /// 동의는 끝났고 프로필만 없는 복구 — 이름 입력부터.
    @MainActor
    func test_세션복구_온보딩진입() {
        let state = AuthFeature.State(resuming: .onboarding)

        XCTAssertEqual(state.path.count, 1)
        XCTAssertEqual(state.profileRegistered, false)
        guard case .naming = state.path[0] else {
            return XCTFail("복구 진입은 이름 입력 화면이어야 한다")
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeStore(state: AuthFeature.State = .init()) -> TestStore<AuthFeature.State, AuthFeature.Action> {
        TestStore(initialState: state) { AuthFeature() }
    }
}
