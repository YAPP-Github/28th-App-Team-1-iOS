//
//  LiveMyPageBootstrap.swift
//  FeatureMyPageExample
//
//  Created by 서정원 on 26/08/08.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainAuthInterface
import DomainUserInterface
import FeatureMyPageImplementation
import Foundation
import SwiftUI

// 실서버 하네스 — «토큰만 넣으면 마이페이지가 실데이터로 선다» 부트스트랩 (FeatureInterview 선례 이식).
// ① 주입 토큰을 **기본 TokenStore(liveValue = Example 자체 Keychain)에 저장** ② 프로필 1콜로 토큰·계정
// 상태를 먼저 진단 ③ MyPageFeature 진입. 진입 조회 3종(프로필·포폴·리포트)·포폴 삭제·업로드(register·
// status 폴링·PortfolioFileReader 파일 읽기)는 오버라이드가 없어 그대로 liveValue 가 탄다 —
// 로그아웃·탈퇴만 스텁이다(계정 파괴 방지, makeStore 참조).
//
// ⚠️ withDependencies 로 tokenStore 를 스코프 오버라이드하면 안 된다 — AuthorizedNetworkClient
// liveValue(엔진)는 전역 캐시 싱글턴이라 내부 @Dependency(\.tokenStore)가 스코프 밖(기본값)으로
// 해소된다(2026-08-02 시뮬 재현: 요청 없이 NotAuthenticatedError). 그래서 엔진이 실제로 읽는 기본
// 스토어에 직접 저장한다. 3h 테스트 토큰 전제 — refresh 는 빈 값(재발급 미사용).
// Example 전용이라 TCA 리듀서 없이 순수 SwiftUI 상태로 둔다.
struct LiveMyPageBootstrap: View {
    let accessToken: String

    /// 부트스트랩 진행 상태 — 실패 사유를 화면에 그대로 드러내 스모크 디버깅을 돕는다.
    enum Stage {
        case idle
        case running(String)
        case failed(String)
        case ready(StoreOf<MyPageFeature>)
    }

    @State private var stage: Stage = .idle

    var body: some View {
        Group {
            switch stage {
            case .idle:
                ProgressView("실서버 부트스트랩 시작")
            case let .running(step):
                ProgressView(step)
            case let .failed(reason):
                VStack(spacing: 16) {
                    Text("부트스트랩 실패").font(.headline)
                    Text(reason)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    // 일시적 네트워크 실패용 우회로 — 같은 토큰으로 다시 탄다. 토큰 만료(3h)면
                    // 스킴 Run 환경변수를 새 토큰으로 고치고 다시 실행해야 한다.
                    Button("재시도") {
                        Task { await bootstrap() }
                    }
                }
            case let .ready(store):
                MyPageView(store: store)
            }
        }
        .task { await bootstrap() }
    }

    @MainActor
    private func bootstrap() async {
        // 스킴 env 복사 실수 흡수 — 줄바꿈·공백·따옴표·Bearer 접두를 벗기고 JWT 형태(점 2개)를 검증한다.
        let token = Self.normalize(accessToken)
        guard token.split(separator: ".").count == 3 else {
            stage = .failed("토큰 형태가 JWT(점 2개)가 아니에요 — 토큰 한 줄 전체를 복사했는지 확인 (현재 점 \(token.filter { $0 == "." }.count)개, \(token.count)자)")
            return
        }

        var step = "액세스 토큰 저장"
        stage = .running(step)
        print("⛳️ [HARNESS] \(step)")
        do {
            // 기본 TokenStore(liveValue = Keychain) — AuthorizedNetworkClient 엔진이 읽는 그 스토어다.
            @Dependency(\.tokenStore) var tokenStore
            try tokenStore.save(AuthTokens(accessToken: token, refreshToken: ""))

            // 토큰 유효성·계정 상태 진단 — 화면의 진입 조회는 3콜을 «불러오지 못했어요» 알럿 하나로
            // 뭉뚱그리므로(부분 성공 없음), 그 전에 사유가 드러나는 1콜을 먼저 태운다.
            step = "프로필 확인"
            stage = .running(step)
            print("⛳️ [HARNESS] \(step)")
            @Dependency(\.userClient) var userClient
            let profile = try await userClient.profile()
            let careerText = profile.careerYears.map(String.init) ?? "미등록"
            print("⛳️ [HARNESS] 프로필 — 직군: \(profile.jobRole ?? "미등록") / 연차: \(careerText) / 잔여 이용권: \(profile.remainingTicketCount)")

            stage = .ready(makeStore())
        } catch {
            print("⛳️ [HARNESS] \(step) 실패: \(String(describing: error))")
            stage = .failed("\(step) 실패: \(String(describing: error))")
        }
    }

    private func makeStore() -> StoreOf<MyPageFeature> {
        Store(initialState: MyPageFeature.State()) {
            MyPageFeature()
        } withDependencies: {
            // 계정 파괴 방지 — 탈퇴·로그아웃은 live 하네스에서도 서버로 나가지 않는다(조립 슬라이스에서 실앱으로 검증).
            $0.authClient.logout = { print("⛳️ [HARNESS] logout 스텁 — delegate 확인용") }
            $0.userClient.withdraw = { print("⛳️ [HARNESS] withdraw 스텁 — 실서버 탈퇴 금지") }
        }
    }

    /// 복사 흔적 제거 — 앞뒤 공백·줄바꿈·따옴표, 대소문자 무관 `Bearer ` 접두.
    static func normalize(_ raw: String) -> String {
        var token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        token = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        if token.lowercased().hasPrefix("bearer ") {
            token = String(token.dropFirst("bearer ".count))
        }
        return token.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
