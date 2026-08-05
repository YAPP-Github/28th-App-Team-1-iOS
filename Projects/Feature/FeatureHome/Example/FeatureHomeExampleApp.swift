//
//  FeatureHomeExampleApp.swift
//  FeatureHomeExample
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import DomainPortfolioInterface
import DomainUserInterface
import FeatureHomeImplementation
import Foundation
import SwiftUI

@main
struct FeatureHomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            // 실전(AppView)과 같은 조건 — 로고 내비바는 시스템 바 기반이라 스택 밖에선 안 그려진다.
            NavigationStack {
                HomeView(
                    store: Store(initialState: HomeFeature.State()) {
                        HomeFeature()
                    } withDependencies: {
                        // Example 은 Implementation 을 link 하지 않는다 — 진입 로드 2종을 가짜로 채워
                        // 네트워크 없이 홈을 돈다(안 채우면 liveValue 부재로 unimplemented 트랩).
                        $0.userClient.profile = { Self.profile }
                        $0.portfolioClient.list = { Self.portfolios }
                    }
                )
            }
        }
    }

    /// 가짜 프로필 — 잔여 2회로 «소진 아님» 분기를 탄다.
    private static let profile = UserProfile(
        userId: UUID(uuidString: "00000000-0000-0000-0000-0000000000e1")!,
        name: "재원",
        email: "hilit@kakao.com",
        provider: "KAKAO",
        jobRole: "BACKEND",
        jobRoleLabel: "백엔드",
        careerYears: 3,
        remainingTicketCount: 2
    )

    /// 가짜 포폴 1건(READY) — 면접 시작 카드가 «이전 정보 재사용» 변형으로 뜬다.
    /// 빈 배열로 바꾸면 «처음» 변형을 볼 수 있다.
    private static let portfolios = [
        Portfolio(
            portfolioId: UUID(uuidString: "00000000-0000-0000-0000-0000000000e2")!,
            fileName: "포트폴리오.pdf",
            fileSize: 3_355_443,
            pageCount: 12,
            status: .ready,
            // 2026-07-31 00:00 UTC — 데모가 흔들리지 않게 고정값.
            uploadedAt: Date(timeIntervalSince1970: 1_785_456_000)
        )
    ]
}
