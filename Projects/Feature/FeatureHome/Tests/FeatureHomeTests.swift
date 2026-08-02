//
//  FeatureHomeTests.swift
//  FeatureHomeTests
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainPortfolioInterface
import DomainUserInterface
import Foundation
import Testing

@testable import FeatureHomeImplementation

@MainActor
struct HomeEntryLoadTests {
    private static func profile(name: String? = "재원", remaining: Int = 3) -> UserProfile {
        UserProfile(
            userId: UUID(uuidString: "00000000-0000-0000-0000-0000000000a1")!,
            name: name,
            email: nil,
            provider: "KAKAO",
            jobRole: "BACKEND",
            jobRoleLabel: "백엔드",
            careerYears: 3,
            remainingTicketCount: remaining
        )
    }

    private static func portfolio(status: PortfolioProcessingStatus = .ready) -> Portfolio {
        Portfolio(
            portfolioId: UUID(uuidString: "00000000-0000-0000-0000-0000000000a2")!,
            fileName: "포트폴리오.pdf",
            fileSize: 3_355_443,
            pageCount: 12,
            status: status,
            uploadedAt: Date(timeIntervalSince1970: 1_785_456_000)
        )
    }

    @Test("홈 진입은 프로필·포폴을 함께 싣고 면접 시작 변형을 «재사용» 으로 바꾼다")
    func entryLoadFillsNameRemainingAndPortfolio() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 2) }
            $0.portfolioClient.list = { [Self.portfolio()] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.remainingChances = 2
            $0.startInterview.portfolio = StartInterviewFeature.Portfolio(
                fileName: "포트폴리오.pdf",
                uploadedAt: Date(timeIntervalSince1970: 1_785_456_000),
                byteCount: 3_355_443
            )
            $0.startInterview.variant = .hasPortfolio
        }
    }

    @Test("포폴 로드가 실패해도 프로필 값은 그대로 반영된다")
    func portfolioFailureKeepsProfileValues() async {
        struct LoadFailure: Error {}
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 1) }
            $0.portfolioClient.list = { throw LoadFailure() }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.remainingChances = 1
            // 포폴은 «모른다» 라서 직전 값을 유지한다 — nil 로 지우면 없는 것처럼 보인다.
            $0.startInterview.variant = .first
        }
    }

    @Test("프로필 로드가 실패하면 소진이 아니라 «모른다» 로 둔다")
    func profileFailureIsNotExhausted() async {
        struct LoadFailure: Error {}
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { throw LoadFailure() }
            $0.portfolioClient.list = { [] }
        }

        await store.send(.view(.onAppear))
        // 잔여는 nil 그대로 — 0 으로 떨어뜨리면 «무료 횟수를 모두 사용했어요» 가 떠서
        // 시작 경로가 [홈으로] 하나로 막힌다. 변형도 초기값 `.first` 에서 안 움직인다.
        await store.receive(\.inner.entryLoaded)
    }

    @Test("잔여 0 이면 포폴이 있어도 소진 변형이 이긴다")
    func exhaustedWinsOverPortfolio() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 0) }
            $0.portfolioClient.list = { [Self.portfolio()] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.portfolio = StartInterviewFeature.Portfolio(
                fileName: "포트폴리오.pdf",
                uploadedAt: Date(timeIntervalSince1970: 1_785_456_000),
                byteCount: 3_355_443
            )
            $0.startInterview.variant = .exhausted
        }
    }

    @Test("처리 중(PROCESSING) 포폴은 재사용 카드에 걸지 않는다")
    func processingPortfolioIsNotReusable() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(remaining: 3) }
            $0.portfolioClient.list = { [Self.portfolio(status: .processing)] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.userName = "재원"
            $0.startInterview.userName = "재원"
            $0.startInterview.remainingChances = 3
            $0.startInterview.variant = .first
        }
    }

    @Test("이름이 비어 오면 앞서 그리던 이름을 지우지 않는다")
    func emptyNameKeepsPreviousName() async {
        let store = TestStore(initialState: HomeFeature.State(userName: "재원")) {
            HomeFeature()
        } withDependencies: {
            $0.userClient.profile = { Self.profile(name: nil, remaining: 3) }
            $0.portfolioClient.list = { [] }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.inner.entryLoaded) {
            $0.startInterview.remainingChances = 3
        }
    }
}
