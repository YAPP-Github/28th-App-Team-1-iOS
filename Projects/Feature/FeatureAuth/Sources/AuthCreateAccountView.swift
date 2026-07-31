//
//  AuthCreateAccountView.swift
//  FeatureAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

// Figma: «Create_Account» https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-14399

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
                socialButtons
            }
        }
        .onAppear { isRevealed = true }
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
    private var logoMark: some View {
        Image.Logo.hilit
            .resizable()
            .scaledToFit()
            .frame(width: SplashView.logoSize.width, height: SplashView.logoSize.height)
            .offset(y: SplashView.logoCenterOffsetY)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }

    // MARK: - 소셜 로그인

    private var socialButtons: some View {
        VStack(spacing: .ds(.p8)) {
            SocialLoginButton(
                title: "카카오톡으로 로그인",
                icon: Image.Logo.kakaoWithBg24,
                // @ds(color): #FEE500 — 카카오 브랜드 배경. 팔레트 23색에 없다 (Figma 변수명 `kakao`)
                background: Color(red: 254 / 255, green: 229 / 255, blue: 0),
                foreground: Color.HilitBlack.b900
            ) {
                send(.userTappedSignIn(.kakao))
            }
            .revealed(isRevealed, order: 0)

            SocialLoginButton(
                title: "Apple로 로그인",
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
        .disabled(store.isLoading)
        // 로딩 표시 — 재탭 차단은 리듀서 guard 가 이미 하고, 여기선 눌린 게 보이게만 한다.
        // DS `.hilitButtonLoading` 은 `ButtonLarge` 가 읽는 Environment 라 이 커스텀 버튼엔 걸리지 않는다.
        // State 가 provider 를 안 들고 있어(isLoading: Bool) 어느 쪽을 눌렀는지 구분하지 않는다.
        .opacity(store.isLoading ? 0.5 : 1)
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
// @ds(component): button-large/login (Figma 3756:15525 카카오 · 3756:15531 Apple) — h56·px8/py16·gap8,
//   라벨 sub7. DS `ButtonLarge` 는 title(String) 단일 슬롯 + b800/white 고정이라 아이콘도 브랜드 색도 담을 수 없다.
//   두 번째 사용처가 생기면 Shared 승격 후보 (아이콘 슬롯을 가진 large 티어).
private struct SocialLoginButton: View {
    let title: String
    let icon: Image
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .ds(.p8)) {
                // 아이콘은 24px 로 그려진 에셋을 그대로 쓴다 — 크기 지정·틴트 없음(DS 규칙).
                icon

                Text(title)
                    .dsTypography(.sub7)
                    .foregroundStyle(foreground)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .ds(.p8))
            .padding(.vertical, .ds(.p16))
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

#Preview("소셜 로그인 — 로그인 진행 중") {
    var state = AuthCreateAccountFeature.State()
    state.isLoading = true
    return AuthCreateAccountView(
        store: Store(initialState: state) {
            AuthCreateAccountFeature()
        }
    )
}
