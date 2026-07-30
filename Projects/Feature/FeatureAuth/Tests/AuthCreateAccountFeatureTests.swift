//
//  AuthCreateAccountFeatureTests.swift
//  FeatureAuthTests
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import XCTest

@testable import FeatureAuthImplementation

final class AuthCreateAccountFeatureTests: XCTestCase {
    @MainActor
    func test_로그인성공_토큰수신후_delegate신호() async {
        let credential = SocialCredential.kakao(
            accessToken: "test-at",
            refreshToken: "test-rt"
        )
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in credential }
        }

        await store.send(.view(.userTappedSignIn(.kakao))) {
            $0.isLoading = true
        }
        await store.receive(\.inner.signInFinished.success, credential) {
            $0.isLoading = false
        }
        await store.receive(\.delegate.authenticated)
    }

    @MainActor
    func test_취소_얼럿없이_조용히복귀() async {
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in throw AuthError.cancelled }
        }

        await store.send(.view(.userTappedSignIn(.kakao))) {
            $0.isLoading = true
        }
        await store.receive(\.inner.signInFinished.failure) {
            $0.isLoading = false
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
            $0.isLoading = true
        }
        await store.receive(\.inner.signInFinished.failure) {
            $0.isLoading = false
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
        initialState.isLoading = true
        let store = TestStore(initialState: initialState) {
            AuthCreateAccountFeature()
        }
        await store.send(.view(.userTappedSignIn(.kakao)))
    }

    @MainActor
    func test_애플로그인성공_provider전달_delegate신호() async {
        let credential = SocialCredential.apple(
            identityToken: "test-identity-token",
            authorizationCode: "test-authorization-code"
        )
        let store = TestStore(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        } withDependencies: {
            $0.authClient.signIn = { provider in
                XCTAssertEqual(provider, .apple)
                return credential
            }
        }

        await store.send(.view(.userTappedSignIn(.apple))) {
            $0.isLoading = true
        }
        await store.receive(\.inner.signInFinished.success, credential) {
            $0.isLoading = false
        }
        await store.receive(\.delegate.authenticated)
    }
}
