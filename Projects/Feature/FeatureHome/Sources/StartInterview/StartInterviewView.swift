//
//  StartInterviewView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_StartInterview»                       https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-1612
//        «Home_StartInterview_TrialEnded»            https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-9566
//        «Home_DuringInterview»                      https://www.figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-5890
//        «Home_DuringInterview_ExitConfirmation»     https://www.figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-5873

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

/// 면접 시작 — 시안 3장을 `StartInterviewFeature.Variant` 로, 그중 진행 중 시안의 확인 단계를
/// `isConfirmingRestart` 로 분기한다.
///
/// 네 장의 골격은 같다: 커튼 그린 배경 + 좌상단 인사말(color-burn) + 중앙 흰 카드 + 하단 CTA.
/// 갈리는 건 **인사말 문구 · 카드 내용 · CTA** 셋이다 — 확인 단계를 별도 화면으로 두지 않는 이유도
/// 이것이다(갈리는 세 자리 말고는 전부 같아서, 화면을 새로 띄우면 배경·내비바가 두 겹이 된다).
///
/// **화면이 아니라 홈 씬의 한 겹**이다 — 리포트 시트 뒤에 늘 깔려 있고 시트가 내려간 만큼 드러난다
/// (`HomeView`). 그래서 그린 배경·내비바를 여기서 갖지 않는다. 나가기(X)는 홈 내비바가 «시트를 도로
/// 올린다» 로 처리한다 — 소진 시안엔 시안상 바가 없지만, 씬에 늘 바가 있어 X 도 함께 뜬다
/// (하단 «홈으로» 와 결과가 같아 해롭지 않다).
///
/// 카드 안 값(잔여 횟수·남은 질문 수)은 `StartInterviewFeature.State` 소유고, 표기만 이 뷰가 만든다.
@ViewAction(for: StartInterviewFeature.self)
public struct StartInterviewView: View {
    @Bindable public var store: StoreOf<StartInterviewFeature>

    public init(store: StoreOf<StartInterviewFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            greeting
                // @ds(spacing): 54 — 내비바 아래 ~ 인사말 (시안 프레임 top 141 − 상태바 43 − 내비바 44)
                .padding(.top, 54)
                // @ds(spacing): 80 — 인사말 아래 ~ 카드 위 (시안 텍스트 bottom 255 → 카드 top 335). spacing 토큰은 4~24
                .padding(.bottom, 80)
            card
            Spacer(minLength: 0)
            callToAction
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 인사말

    private var greeting: some View {
        Text(greetingText)
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(component): mix-blend-mode color-burn — 인사말이 배경 커튼과 타서 초록으로 보이는 효과. DS 에 블렌드 규칙 없음
            .blendMode(.colorBurn)
    }

    /// 시안의 줄바꿈을 그대로 옮긴다 — 시안마다 고정 폭에 맞춰 끊어져 있다.
    /// 이름은 프로필 로드 결과라 응답 전엔 비어 있다 — 그때는 «님,» 만 남지 않게 이름 줄을 뺀다.
    private var greetingText: String {
        let namePrefix = store.userName.isEmpty ? "" : "\(store.userName)님,\n"
        switch store.variant {
        case .first: return namePrefix + "지금부터 면접을\n시작해 볼까요?"
        // 확인 단계는 되묻는 문장으로 갈아탄다 — 시안에 이름이 없다(묻는 대상이 사람이 아니라 행동이라서).
        case .inProgress:
            return store.isConfirmingRestart
                ? "처음부터\n시작하시겠어요?"
                : namePrefix + "진행 중인\n면접이 있어요"
        case .exhausted: return namePrefix + "무료 횟수를 모두\n사용했어요"
        }
    }

    // MARK: - 카드

    @ViewBuilder private var card: some View {
        switch store.variant {
        case .first:
            remainingChancesCard(icon: Image.Img.oppO)
        case let .inProgress(remainingQuestionCount):
            if store.isConfirmingRestart {
                restartConfirmCard
            } else {
                inProgressCard(remainingQuestionCount: remainingQuestionCount)
            }
        case .exhausted:
            remainingChancesCard(icon: Image.Img.oppX)
        }
    }

    /// 진행 중 면접 카드 — Figma 443:5906. 물음표 말풍선 + «면접 상태» + 남은 질문 수.
    /// 남은 질문이 0 이어도 «0개의 질문이 남았어요» 로 그린다 — 그건 서버가 held 로 준 세션의 값이고,
    /// 화면이 «면접이 끝났다» 를 지어낼 자리가 아니다(잔여 횟수 nil 을 소진으로 읽지 않는 것과 같은 규칙).
    private func inProgressCard(remainingQuestionCount: Int) -> some View {
        HomeModal(
            "\(remainingQuestionCount)개의 질문이 남았어요",
            subTitle: "면접 상태",
            icon: Image.Img.oppEllipsis
        )
        .padding(.horizontal, .ds(.p24))
    }

    /// 처음부터 시작 확인 카드 — Figma 443:5889. 위 카드에 안내줄(`showInfoField=true`)이 하나 더 붙는다.
    private var restartConfirmCard: some View {
        HomeModal(
            "지금까지 진행한 면접 내용으로\n레포트가 제작돼요",
            subTitle: "처음부터 시작하면",
            icon: Image.Img.oppEllipsis,
            info: "이용권이 하나 차감됩니다."
        )
        .padding(.horizontal, .ds(.p24))
    }

    /// 잔여 횟수 카드 — Figma «home modal» property1=opp (3632:10988). 일러스트 + 보조문구 + 값.
    /// 시안의 `showInfoField` 축은 두 시안 모두 false 라 안내줄을 두지 않았다.
    private func remainingChancesCard(icon: Image) -> some View {
        modalCard {
            icon
            VStack(spacing: .ds(.p4)) {
                Text("남은 면접 기회")
                    .dsTypography(.body6)
                    .foregroundStyle(Color.GrayScale.g500)
                // 잔여를 모르는 동안(프로필 응답 전·실패)엔 숫자 줄을 뺀다 — «0회» 로 떨어뜨리면
                // 서버가 말하지 않은 소진을 화면이 지어낸다.
                if let remainingChances = store.remainingChances {
                    Text("\(remainingChances)회")
                        .dsTypography(.sub4)
                        .foregroundStyle(Color.HilitBlack.b800)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    /// 흰 카드 판 — Figma «home modal» (p24 · gap12 · 모서리 0 · 폭 327 = 375 − 24×2).
    /// 같은 판의 DS 판이 `HomeModal` 이고 진행 중 시안 두 장은 그걸 쓴다. 여기 남은 두 장이 슬롯
    /// 컨테이너를 계속 쓰는 건 값 조각이 빠질 수 있어서다 — 잔여 미확정이면 숫자 줄이 통째로 빠지는데
    /// `HomeModal` 의 타이틀은 옵셔널이 아니다.
    // TODO: 옵셔널 타이틀이 `HomeModal` 로 흡수되면 이 판을 지운다.
    private func modalCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: .ds(.p12)) {
            content()
        }
        .padding(.ds(.p24))
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
        .padding(.horizontal, .ds(.p24))
    }

    // MARK: - 하단 CTA

    @ViewBuilder private var callToAction: some View {
        switch store.variant {
        case .first:
            ButtonLarge("시작하기", .bottom) { send(.userTappedStart) }
        // 두 단계 모두 «되돌리기 | 진행» 배치다 — 파괴적인 쪽(처음부터)이 왼쪽, 이어가는 쪽이 오른쪽.
        case .inProgress:
            if store.isConfirmingRestart {
                ButtonLarge(.bottom, tone: .dark) {
                    Button("뒤로가기") { send(.userTappedRestartCancel) }
                } trailing: {
                    Button("처음부터 시작") { send(.userTappedRestartConfirm) }
                }
            } else {
                ButtonLarge(.bottom, tone: .dark) {
                    Button("처음부터 시작") { send(.userTappedRestart) }
                } trailing: {
                    Button("이어서 진행") { send(.userTappedResume) }
                }
            }
        case .exhausted:
            ButtonLarge("홈으로", .bottom) { send(.userTappedBackToHome) }
        }
    }
}

// MARK: - Previews

/// 씬의 한 겹이라 단독으로는 배경이 없다 — 프리뷰에서만 홈이 깔아 주는 배경을 흉내 낸다.
/// State 기본값은 중립(이름 없음·잔여 미확정)이라 **시안 값은 여기서 명시로 넘긴다**.
private func previewLayer(
    _ variant: StartInterviewFeature.Variant,
    remainingChances: Int?,
    isConfirmingRestart: Bool = false
) -> some View {
    ZStack {
        HomeGreenBackdrop()
            .ignoresSafeArea()
        StartInterviewView(
            store: Store(
                initialState: StartInterviewFeature.State(
                    variant: variant,
                    isConfirmingRestart: isConfirmingRestart,
                    userName: "재원",
                    remainingChances: remainingChances
                )
            ) {
                StartInterviewFeature()
            }
        )
    }
    .compositingGroup()
}

#Preview("처음 — 정보 입력 전") {
    previewLayer(.first, remainingChances: 3)
}

#Preview("무료 횟수 소진") {
    previewLayer(.exhausted, remainingChances: 0)
}

// held 세션 조회 API 가 없어(미결 6-3) 앱에서는 아직 이 두 장에 도달할 수 없다 — 확인은 여기가 전부다.
#Preview("진행 중 면접") {
    previewLayer(.inProgress(remainingQuestionCount: 2), remainingChances: 3)
}

#Preview("진행 중 면접 — 처음부터 확인") {
    previewLayer(.inProgress(remainingQuestionCount: 2), remainingChances: 3, isConfirmingRestart: true)
}

// 프로필이 죽었거나 아직 안 온 자리 — 숫자 줄만 빠지고 시작 경로는 살아 있다.
#Preview("처음 — 잔여 미확정") {
    previewLayer(.first, remainingChances: nil)
}
