//
//  AuthCreateAccountView.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

// Figma: «Create_Account» https://www.figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-5802
//   (2026-08-15 개정 — 버튼 로고 24→34·라벨 head4 영문. 이전 시안 ZG7FUxWCvITmnvzZi7fpTS node 3632-14399)

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// AuthCreateAccount(A0) — 가입·로그인 단일 진입점. 로고 + 소셜 로그인 버튼 2개뿐인 화면.
///
/// 시안의 상태 바·홈 인디케이터는 iOS 시스템 크롬이라 그리지 않는다 (`SplashView` 와 같은 판단).
/// PRD Part7 확정(2026-07-29): 하단은 비운다 — 간주 문구·약관 열람 링크 모두 없음(열람은 AuthTerms [보기] 전담).
///
/// **Splash 에서 넘어오는 전환** — 로고는 움직이지 않고 버튼만 올라온다. 근거는 `logoMark`·`Reveal` 주석.
@ViewAction(for: AuthCreateAccountFeature.self)
public struct AuthCreateAccountView: View {
    @Bindable public var store: StoreOf<AuthCreateAccountFeature>

    /// 등장 애니메이션 스위치. 화면 진입 연출뿐이라 리듀서 State 로 올리지 않는다 —
    /// 리듀서에 넣으면 이 값 하나 때문에 모든 기존 테스트가 상태 단정을 다시 써야 한다.
    @State private var isRevealed = false

    public init(store: StoreOf<AuthCreateAccountFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.BlackWhite.white.ignoresSafeArea()

            logoMark

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if store.showsReviewCodeField {
                    reviewCodeField
                }

                socialButtons
            }
        }
        .onAppear { isRevealed = true }
        .dismissesKeyboardOnTap()
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - 로고

    /// hilit 워드마크 — Splash 와 **같은 크기·같은 좌표**다 (둘 다 171×72, 화면 중심 대비 −50).
    /// 시안 확인: Splash 로고 node 3768:5763 = x102 y320 171×72, 이 화면 node 3768:5787 = x102 y320 171×72.
    /// 그래서 전환에서 로고는 이동도 페이드도 하지 않는다 — 두 화면을 잇는 고정점 역할이고,
    /// 여기에 모션을 넣으면 없던 움직임이 생겨 오히려 연속성이 깨진다.
    ///
    /// 값은 `SplashView` 가 static 으로 노출한 시작 프레임을 그대로 읽는다 (같은 타겟). 복사하면
    /// 한쪽만 바뀌어도 컴파일은 통과하고 눈으로만 어긋나므로, 상수를 나누지 않는다.
    /// 크기·오프셋의 `@ds` 태그도 그 선언에 붙어 있어 여기서 중복하지 않는다.
    ///
    /// `ignoresSafeArea` 는 필수다 — Splash 가 화면 전체 중심을 기준으로 로고를 놓기 때문에,
    /// 안전영역 기준으로 중심을 잡으면 상·하 인셋 차이만큼(375×812 에서 5pt) 아래로 밀려 전환이 튄다.
    /// 탭 제스처는 **로고 실제 영역(171×72)에만** 붙인다 — 아래 화면 전체로 늘리는 `frame` 뒤에 걸면
    /// 빈 배경 어디를 눌러도 카운터가 오른다.
    private var logoMark: some View {
        Image.Logo.hilit
            .resizable()
            .scaledToFit()
            .frame(width: SplashView.logoSize.width, height: SplashView.logoSize.height)
            .onTapGesture { send(.userTappedLogo) }
            .offset(y: SplashView.logoCenterOffsetY)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }

    // MARK: - 심사용 코드 로그인

    /// 스토어 심사자용 대체 로그인 — 로고 5탭으로 열린다. 카카오 로그인이 심사 기기에서 막히는 경우
    /// (해외 IP 이상 로그인 감지·새 기기 인증)를 위한 우회로다. 경로는 App Review 노트에 적어 공개한다.
    ///
    /// 코드 자체는 앱에 없다 — 심사자가 입력한 값을 서버가 판정한다(`AuthClient.loginWithReviewCode`).
    /// 시안에 없는 화면이라 DS 표준 컴포넌트만 조립하고 새 값을 만들지 않는다.
    private var reviewCodeField: some View {
        VStack(spacing: .ds(.p8)) {
            HilitTextField("심사용 코드", text: $store.reviewCode)

            ButtonLarge("데모 계정으로 로그인", .modal) {
                send(.userTappedReviewCodeSignIn)
            }
            .disabled(!store.isReviewCodeSubmittable)
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.bottom, .ds(.p16))
    }

    // MARK: - 소셜 로그인

    private var socialButtons: some View {
        VStack(spacing: .ds(.p8)) {
            SocialLoginButton(
                title: "Sign in with Kakao",
                icon: Image.Logo.kakaoWithBg24,
                background: Color.Brand.kakao,
                foreground: Color.HilitBlack.b900
            ) {
                send(.userTappedSignIn(.kakao))
            }
            .revealed(isRevealed, order: 0)

            SocialLoginButton(
                title: "Sign in with Apple",
                icon: Image.Logo.appleWithBg24,
                background: Color.HilitBlack.b900,
                foreground: Color.BlackWhite.white
            ) {
                send(.userTappedSignIn(.apple))
            }
            .revealed(isRevealed, order: 1)
        }
        .padding(.horizontal, .ds(.p20))
        // @ds(spacing): 15 — 버튼 블록과 안전영역 사이. 시안 절대좌표(블록 y643 + h120, 프레임 h812)로
        //   화면 하단까지 49pt 이고 거기서 홈 인디케이터 안전영역 34pt 를 뺀 값. 스케일(4~24)에 없다
        .padding(.bottom, 15)
        // 로딩 표시는 안 든다 — 서버 세션 교환(login) 동안은 AppView 의 전역 LoadingModal 이 덮고,
        // 그 앞 소셜 SDK 구간은 제공자 시트가 화면을 가린다. 재탭 차단은 리듀서 guard 몫.
    }
}

// MARK: - 등장 애니메이션

/// Splash → CreateAccount 전환의 버튼 등장 파라미터.
///
/// **Figma 에 모션 데이터가 없다** (`get_motion_context` 가 두 노드 모두 `{"nodes":[]}`) — 아래는 코드에서 정한 값이다.
/// - `delay 0.15` — 로고가 제자리에 그대로 있어(위 `logoMark`) 화면이 바뀐 순간엔 아무 변화도 없다.
///   한 박자 쉬고 버튼이 올라와야 「로고는 그대로, 버튼만 새로 생겼다」로 읽힌다. 즉시 시작하면
///   화면 전환 자체와 겹쳐 무엇이 움직인 건지 구분되지 않는다.
/// - `duration 0.4` + `easeOut` — 등장(enter)은 감속 커브가 표준이다(도착하는 움직임). iOS 기본 전환(≈0.35)보다
///   살짝 길게 잡아 24pt 이동이 눈에 남게 한다.
/// - `offset 24` — 아래에서 올라오는 거리. 버튼 높이(56)의 절반 미만이라 「튀어 오르는」 느낌 없이 방향만 전달한다.
///   레이아웃 간격이 아니라 모션 변위라 spacing 토큰을 쓰지 않는다.
/// - `stagger 0.07` — 카카오 → Apple 순서가 읽히는 최소 간격. 더 벌리면 두 번째 버튼이 늦은 것처럼 보인다.
private enum Reveal {
    static let delay = 0.15
    static let duration = 0.4
    static let stagger = 0.07
    static let offset: CGFloat = 24

    static func animation(order: Int) -> Animation {
        .easeOut(duration: duration).delay(delay + stagger * Double(order))
    }
}

private extension View {
    /// 아래에서 올라오며 페이드인. `order` 는 순차 등장 순번.
    ///
    /// 뷰를 넣고 빼는 `if` + `transition` 대신 offset·opacity 를 쓴다 — 버튼이 항상 계층에 있어
    /// 첫 등장에서 transition 이 씹히는 일이 없고, 레이아웃도 재계산되지 않는다.
    /// 커브가 행마다 달라야(stagger) 해서 전역 `withAnimation` 이 아니라 행별 `.animation(_:value:)` 로 건다.
    func revealed(_ isRevealed: Bool, order: Int) -> some View {
        offset(y: isRevealed ? 0 : Reveal.offset)
            .opacity(isRevealed ? 1 : 0)
            .animation(Reveal.animation(order: order), value: isRevealed)
    }
}

// MARK: - 소셜 로그인 버튼

/// 소셜 로그인 버튼 — 아이콘 + 라벨, 브랜드 색 판.
///
// @ds(component): button-large/login (Figma 2030:7288 카카오 · 2030:7287 Apple) — h56·px8/py11·gap8,
//   로고 34, 라벨 head4. DS `ButtonLarge` 는 title(String) 단일 슬롯 + b800/white 고정이라 아이콘도 브랜드 색도 담을 수 없다.
//   두 번째 사용처가 생기면 Shared 승격 후보 (아이콘 슬롯을 가진 large 티어).
private struct SocialLoginButton: View {
    /// 시안의 브랜드 로고 변(34) — 에셋은 24px 판뿐이라 확대해 쓴다.
    // @ds(icon): 34 → Logo.{kakao,apple}WithBg24 — 시안이 같은 24px 컴포넌트를 34 로 인스턴스한 것이라
    //   재드로잉이 아니다(순수 확대). 정수배가 아니라 image.md 의 «정수배» 예외에는 못 들어가니,
    //   34 판 에셋이 생기면 이 frame 을 지우고 교체한다.
    private static let iconSize: CGFloat = 34

    let title: String
    let icon: Image
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .ds(.p8)) {
                // 틴트는 걸지 않는다(DS 규칙) — 크기만 시안 값으로 맞춘다.
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.iconSize, height: Self.iconSize)

                Text(title)
                    .dsTypography(.head4)
                    .foregroundStyle(foreground)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .ds(.p8))
            // @ds(spacing): 11 — 로고 34 와 합쳐 버튼 높이 56 을 만드는 값(개정 전 24+16·2 와 같은 높이).
            //   스케일(4~24)에 11 이 없다
            .padding(.vertical, 11)
            .background(background)
        }
        .buttonStyle(.plain)
    }
}

#Preview("소셜 로그인") {
    AuthCreateAccountView(
        store: Store(initialState: AuthCreateAccountFeature.State()) {
            AuthCreateAccountFeature()
        }
    )
}

#Preview("심사용 코드 열린 상태") {
    AuthCreateAccountView(
        store: Store(
            initialState: {
                var state = AuthCreateAccountFeature.State()
                state.logoTapCount = AuthCreateAccountFeature.reviewCodeTapThreshold
                return state
            }()
        ) {
            AuthCreateAccountFeature()
        }
    )
}
