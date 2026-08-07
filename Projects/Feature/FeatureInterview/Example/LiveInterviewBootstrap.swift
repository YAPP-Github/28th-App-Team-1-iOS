//
//  LiveInterviewBootstrap.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/08/02.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import DomainPortfolioInterface
import DomainSpeechInterface
import DomainUserInterface
import FeatureInterviewImplementation
import Foundation
import SwiftUI

// 실서버 하네스 — «토큰만 넣으면 면접 한 판이 도는» 부트스트랩 (스펙 2026-08-02 §7).
// ① 주입 토큰을 **기본 TokenStore(liveValue = Example 자체 Keychain)에 저장** ② PortfolioClient.list
// 첫 포트폴리오 ③ createSession ④ 실 sessionId 로 InterviewFeature 진입.
//
// ⚠️ withDependencies 로 tokenStore 를 스코프 오버라이드하면 안 된다 — AuthorizedNetworkClient
// liveValue(엔진)는 전역 캐시 싱글턴이라 내부 @Dependency(\.tokenStore)가 스코프 밖(기본값)으로
// 해소된다(2026-08-02 시뮬 재현: 요청 없이 NotAuthenticatedError → sessionExpired). 그래서 엔진이
// 실제로 읽는 기본 스토어에 직접 저장한다. 24h 테스트 토큰 전제 — refresh 는 빈 값(재발급 미사용).
// 선행 데이터(프로필·포트폴리오)는 테스트 계정에 미리 있어야 한다 — 없으면 실패 사유로 안내.
// Example 전용이라 TCA 리듀서 없이 순수 SwiftUI 상태로 둔다.
struct LiveInterviewBootstrap: View {
    let accessToken: String

    /// 부트스트랩 진행 상태 — 실패 사유를 화면에 그대로 드러내 스모크 디버깅을 돕는다.
    enum Stage {
        case idle
        case running(String)
        case failed(String)
        case ready(StoreOf<ExampleInterviewCoordinator>)
    }

    @State private var stage: Stage = .idle
    /// bootstrap 재진입 가드 — `.task` 재발화(뷰 아이덴티티 변경 시 이전 Task 는 취소 신호만 받고 계속 돈다)나
    /// 겹친 탭이 `createSession` 을 중복 호출해 이용권(희소한 테스트 자원)을 이중 소모하는 것을 막는다.
    @State private var isBootstrapping = false

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
                    // STT_RESET 등으로 세션이 무효화됐을 때의 우회로 — 새 세션을 만든다(스펙 §6 알려진 제약).
                    Button("재시도(새 세션 생성)") {
                        Task { await bootstrap() }
                    }
                }
            case let .ready(store):
                if let outcome = store.outcome {
                    finishedView(outcome)
                } else {
                    InterviewView(store: store.scope(state: \.interview, action: \.interview))
                }
            }
        }
        .task { await bootstrap() }
    }

    /// 실앱이라면 홈으로 돌아갔을 자리 — 하네스엔 홈이 없어 결과만 보여주고 새 세션 동선을 준다.
    /// 여기까지 왔다는 건 코디네이터가 종료 신호를 받았다는 뜻이고, 그 시점엔 카메라·마이크가 이미 꺼져 있다.
    private func finishedView(_ outcome: ExampleInterviewCoordinator.State.Outcome) -> some View {
        VStack(spacing: 16) {
            Text(outcome == .finished ? "면접 정상 종료" : "면접 흐름 이탈").font(.headline)
            Text(outcome == .finished
                ? "산출물이 업로드 큐로 넘어갔어요. 업로드 완주는 콘솔 로그에서 확인하세요."
                : "녹화는 폐기됐어요.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("새 세션으로 다시") {
                Task { await bootstrap() }
            }
        }
    }

    @MainActor
    private func bootstrap() async {
        guard !isBootstrapping else { return }   // 진행 중이면 무시 — 기존 흐름이 상태를 마저 끌고 간다
        isBootstrapping = true
        defer { isBootstrapping = false }

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

            // 세션 생성의 선행 조건 진단 — 프로필 스냅샷(직군·연차)과 잔여 이용권을 눈에 보이게 찍는다.
            step = "프로필 확인"
            stage = .running(step)
            print("⛳️ [HARNESS] \(step)")
            @Dependency(\.userClient) var userClient
            let profile = try await userClient.profile()
            print("⛳️ [HARNESS] 프로필 — 직군: \(profile.jobRole ?? "미등록") / 연차: \(profile.careerYears.map(String.init) ?? "미등록") / 잔여 이용권: \(profile.remainingTicketCount)")
            guard profile.jobRole != nil, profile.careerYears != nil else {
                stage = .failed("프로필 미등록(직군·연차 없음) — 세션 생성이 프로필 스냅샷을 쓰므로 500 의 유력 원인. Dev 앱 가입 온보딩 완주 후 재시도")
                return
            }
            guard profile.remainingTicketCount > 0 else {
                stage = .failed("잔여 이용권 0 — 백엔드에 테스트 계정 충전 요청 후 재시도")
                return
            }

            step = "포트폴리오 조회"
            stage = .running(step)
            print("⛳️ [HARNESS] \(step)")
            @Dependency(\.portfolioClient) var portfolioClient
            guard let portfolio = try await portfolioClient.list().first else {
                stage = .failed("테스트 계정에 포트폴리오가 없어요 — 앱이나 curl 로 1건 등록(READY) 후 재시도")
                return
            }
            print("⛳️ [HARNESS] 포트폴리오 — \(portfolio.fileName ?? "?") / 상태: \(portfolio.status?.rawValue ?? "미상") / id: \(portfolio.portfolioId.uuidString)")
            let uploadedAtText = portfolio.uploadedAt.map { Self.kstFormatter.string(from: $0) } ?? "없음"
            print("⛳️ [HARNESS] uploadedAt(KST 해석) — \(uploadedAtText) ⟵ 실제 업로드 시각과 대조: 9시간 이르면 서버가 UTC 를 타임존 표기 없이 보내는 것")
            guard portfolio.status == .ready else {
                stage = .failed("포트폴리오가 READY 가 아니에요(현재 \(portfolio.status?.rawValue ?? "미상")) — 세션 생성 전제 미충족. READY 포폴 등록 후 재시도")
                return
            }

            step = "면접 세션 생성"
            stage = .running(step)
            print("⛳️ [HARNESS] \(step)")
            @Dependency(\.interviewClient) var interviewClient
            let created = try await interviewClient.createSession(InterviewConfig(portfolioId: portfolio.portfolioId))

            stage = .ready(Store(
                initialState: ExampleInterviewCoordinator.State(sessionId: created.sessionId),
                reducer: { ExampleInterviewCoordinator() },
                withDependencies: {
                    // 실녹음(작업 B) 전 — 번들 샘플로 답변 오디오 seam 만 채운다.
                    // 직접 키 오버라이드는 스코프에 즉시 적용된다(엔진 같은 캐시 싱글턴 내부 전파와는 다른 경로).
                    $0.speechClient.answerAudio = { await Self.sampleAnswerAudio }
                }
            ))
        } catch {
            print("⛳️ [HARNESS] \(step) 실패: \(String(describing: error))")
            stage = .failed("\(step) 실패: \(String(describing: error))")
        }
    }

    /// 서버 시각을 **KST 로 해석했을 때** 의 표기 — `ServerEnvelope` 의 «타임존 표기 없으면 KST» 가정
    /// (ServerEnvelope.swift 의 D14 코더 주석)을 실값으로 검증하기 위한 스모크 전용 로그.
    /// 실제 업로드 시각보다 9시간 이르게 찍히면 서버가 UTC 를 표기 없이 보내는 것 → 백엔드에 오프셋 표기 요청.
    private static let kstFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    /// 복사 흔적 제거 — 앞뒤 공백·줄바꿈·따옴표, 대소문자 무관 `Bearer ` 접두.
    static func normalize(_ raw: String) -> String {
        var token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        token = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        if token.lowercased().hasPrefix("bearer ") {
            token = String(token.dropFirst("bearer ".count))
        }
        return token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 번들 샘플 답변(m4a — `say`+`afconvert` 산출물). 서버가 mp3 를 강제하면 리소스만 교체한다(스펙 §9-1).
    static let sampleAnswerAudio: Data? = Bundle.main
        .url(forResource: "SampleAnswer", withExtension: "m4a")
        .flatMap { try? Data(contentsOf: $0) }
}
