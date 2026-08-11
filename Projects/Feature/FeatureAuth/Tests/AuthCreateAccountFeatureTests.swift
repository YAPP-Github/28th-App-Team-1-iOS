//
//  AuthCreateAccountFeatureTests.swift
//  FeatureAuthTests
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import DomainConsentInterface
import XCTest

@testable import FeatureAuthImplementation

final class AuthCreateAccountFeatureTests: XCTestCase {
    /// 신규 회원 판정값 — 동의 미제출 + 프로필 미등록.
    private static let newUser = LoginResult(consentStatus: .notSubmitted, profileRegistered: false)

    @MainActor
    func test_로그인성공_판정값수신후_delegate신호() async {
        let credential = SocialCredential.kakao(
            accessToken: "test-at",
            refreshToken: "test-rt"
        )
        let result = Self.newUser
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in credential }
            $0.authClient.login = { _ in result }
        }

        await store.send(.view(.userTappedSignIn(.kakao))) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.success, result) {
            $0.isAuthenticating = false
        }
        await store.receive(\.delegate.authenticated, result)
    }

    /// 게이트 판정값은 login 응답이 실어 온다 — 기존 회원(동의 최신 + 프로필 등록)도 그대로 흐른다.
    @MainActor
    func test_기존회원_판정값그대로_delegate전달() async {
        let result = LoginResult(consentStatus: .upToDate, profileRegistered: true)
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in .kakao(accessToken: "at", refreshToken: "rt") }
            $0.authClient.login = { _ in result }
        }

        await store.send(.view(.userTappedSignIn(.kakao))) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.success, result) {
            $0.isAuthenticating = false
        }
        await store.receive(\.delegate.authenticated, result)
    }

    @MainActor
    func test_취소_얼럿없이_조용히복귀() async {
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in throw AuthError.cancelled }
        }

        await store.send(.view(.userTappedSignIn(.kakao))) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.failure) {
            $0.isAuthenticating = false
        }
    }

    @MainActor
    func test_실패_얼럿표시() async {
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in throw AuthError.unexpected }
        }

        await store.send(.view(.userTappedSignIn(.kakao))) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.failure) {
            $0.isAuthenticating = false
            $0.alert = AlertState(
                title: { TextState("알 수 없는 오류가 발생했습니다.") },
                actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
            )
        }
    }

    @MainActor
    func test_로딩중재탭_무시() async {
        var initialState = AuthCreateAccountFeature.State()
        initialState.isAuthenticating = true
        let store = TestStore(initialState: initialState) {
            AuthCreateAccountFeature()
        }
        await store.send(.view(.userTappedSignIn(.kakao)))
    }

    /// 로고 탭이 임계치에 닿아야 심사용 코드 입력이 열린다 — 그 전엔 화면에 없다.
    @MainActor
    func testLogoTapsOpenReviewCodeFieldAtThreshold() async {
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        }

        for tap in 1..<AuthCreateAccountFeature.reviewCodeTapThreshold {
            await store.send(.view(.userTappedLogo)) {
                $0.logoTapCount = tap
            }
            XCTAssertFalse(store.state.showsReviewCodeField)
        }

        await store.send(.view(.userTappedLogo)) {
            $0.logoTapCount = AuthCreateAccountFeature.reviewCodeTapThreshold
        }
        XCTAssertTrue(store.state.showsReviewCodeField)

        // 열린 뒤 탭은 카운터를 올리지 않는다.
        await store.send(.view(.userTappedLogo))
    }

    /// 심사용 코드 경로는 소셜 경로와 같은 inner·delegate 를 탄다 — 다른 건 교환 함수뿐이다.
    @MainActor
    func testReviewCodeLoginSendsCodeAndReusesSocialPath() async {
        let result = LoginResult(consentStatus: .upToDate, profileRegistered: true)
        var state = AuthCreateAccountFeature.State()
        state.logoTapCount = AuthCreateAccountFeature.reviewCodeTapThreshold
        state.reviewCode = "  956ThisisDemo++Hilit  "
        let store = TestStore(initialState: state) {
            AuthCreateAccountFeature()
        } withDependencies: {
            // 앞뒤 공백은 잘라 보낸다 — 심사자 입력에 딸려 오는 공백이 401 을 만들지 않게.
            $0.authClient.loginWithReviewCode = { code in
                XCTAssertEqual(code, "956ThisisDemo++Hilit")
                return result
            }
        }

        await store.send(.view(.userTappedReviewCodeSignIn)) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.success, result) {
            $0.isAuthenticating = false
        }
        await store.receive(\.delegate.authenticated, result)
    }

    /// 코드가 비었으면(공백뿐 포함) 서버를 때리지 않는다 — testValue 가 unimplemented 라 호출 시 실패한다.
    @MainActor
    func testBlankReviewCodeDoesNotCallServer() async {
        var state = AuthCreateAccountFeature.State()
        state.logoTapCount = AuthCreateAccountFeature.reviewCodeTapThreshold
        state.reviewCode = "   "
        let store = TestStore(initialState: state) {
            AuthCreateAccountFeature()
        }

        await store.send(.view(.userTappedReviewCodeSignIn))
    }

    /// 틀린 코드 — 소셜 실패와 같은 얼럿 경로.
    @MainActor
    func testWrongReviewCodeShowsAlert() async {
        var state = AuthCreateAccountFeature.State()
        state.logoTapCount = AuthCreateAccountFeature.reviewCodeTapThreshold
        state.reviewCode = "wrong"
        let store = TestStore(initialState: state) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.loginWithReviewCode = { _ in throw AuthError.invalidCredential }
        }

        await store.send(.view(.userTappedReviewCodeSignIn)) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.failure) {
            $0.isAuthenticating = false
            $0.alert = AlertState(
                title: { TextState("로그인 정보가 올바르지 않습니다.") },
                actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                }
            )
        }
    }

    @MainActor
    func test_애플로그인성공_provider전달_delegate신호() async {
        let credential = SocialCredential.apple(
            identityToken: "test-identity-token",
            authorizationCode: "test-authorization-code"
        )
        let result = Self.newUser
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { provider in
                XCTAssertEqual(provider, .apple)
                return credential
            }
            // 획득한 자격증명이 그대로 서버 교환으로 넘어가는지 — 두 단계가 한 effect 안에 있다.
            $0.authClient.login = { exchanged in
                XCTAssertEqual(exchanged, credential)
                return result
            }
        }

        await store.send(.view(.userTappedSignIn(.apple))) {
            $0.isAuthenticating = true
        }
        await store.receive(\.inner.signInFinished.success, result) {
            $0.isAuthenticating = false
        }
        await store.receive(\.delegate.authenticated, result)
    }
}
