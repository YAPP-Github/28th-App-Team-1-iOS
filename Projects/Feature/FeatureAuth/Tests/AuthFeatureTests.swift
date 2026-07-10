//
//  AuthFeatureTests.swift
//  FeatureAuthTests
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import XCTest

@testable import FeatureAuthImplementation

final class AuthFeatureTests: XCTestCase {
    @MainActor
    func test_로그인성공_토큰수신후_delegate신호() async {
        let credential = SocialCredential(
            provider: .kakao,
            accessToken: "test-at",
            refreshToken: "test-rt"
        )
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in credential }
        }

        await store.send(.userTappedSignIn(.kakao)) {
            $0.isLoading = true
        }
        // AT/RT 수신을 payload로 단언 — State에는 보관하지 않는다(스펙 결정).
        await store.receive(\.signInFinished.success, credential) {
            $0.isLoading = false
        }
        await store.receive(\.delegate.signedIn)
    }

    @MainActor
    func test_취소_얼럿없이_조용히복귀() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in throw AuthError.cancelled }
        }

        await store.send(.userTappedSignIn(.kakao)) {
            $0.isLoading = true
        }
        // 얼럿·delegate 없이 종료 — exhaustive TestStore라 추가 receive가 있으면 실패한다.
        await store.receive(\.signInFinished.failure) {
            $0.isLoading = false
        }
    }

    @MainActor
    func test_실패_얼럿표시() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authClient.signIn = { _ in throw AuthError.unexpected }
        }

        await store.send(.userTappedSignIn(.kakao)) {
            $0.isLoading = true
        }
        await store.receive(\.signInFinished.failure) {
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
        var initialState = AuthFeature.State()
        initialState.isLoading = true
        let store = TestStore(initialState: initialState) {
            AuthFeature()
        }
        // authClient 미주입(testValue = unimplemented) — 가드가 effect 실행 전에
        // 차단함을 함께 증명한다(effect가 돌면 unimplemented가 테스트를 실패시킴).
        await store.send(.userTappedSignIn(.kakao))
    }
}
