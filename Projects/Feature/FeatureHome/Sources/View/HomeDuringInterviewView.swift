//
//  HomeDuringInterviewView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_DuringInterview» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3756-10788
//        «Home_DuringInterview_ExitConfirmation» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-10935

import SharedDesignSystemInterface
import SwiftUI

/// Figma «HomeDuringInterview» — 진행 중 면접·레포트 제작 시점.
///
/// 시안 2종은 **같은 골격**(그린 스트라이프 배경 + 좌상단 헤드라인 + 흰 상태 카드 + 하단 2버튼)에
/// 문구·카드 내용·버튼 라벨만 갈아끼운 것이라, 골격을 한 번 그리고 `Step` 으로 분기한다.
/// - `.status` — 진행 중인 면접 안내 (3756:10788)
/// - `.restartConfirmation` — [처음부터 시작] 탭 후 되묻기 (3632:10935). **모달이 아니다** —
///   딤 없는 전체 화면 전환이라 `.hilitModal` 을 쓰지 않는다.
///
/// 되묻기는 지금 로컬 `@State` 로 굴린다 — 리듀서에 액션이 생기면 `HomeFeature.State` 로 올린다.
struct HomeDuringInterviewView: View {
    /// 화면 안 단계 — 시안 2종. 리듀서 배선 전까지 로컬 상태.
    enum Step: Equatable {
        /// 진행 중인 면접 안내.
        case status
        /// 처음부터 시작 되묻기.
        case restartConfirmation
    }

    let variant: HomeFeature.DuringVariant
    /// 헤드라인 호칭 — `HomeFeature.State` 에 사용자 이름이 없어 기본값으로 둔다(시안 값).
    let userName: String
    /// 카드에 표시할 남은 질문 수 — 진행 중 세션 응답에서 와야 한다(State 미보유, 시안 값).
    let remainingQuestionCount: Int

    @State private var step: Step

    init(
        variant: HomeFeature.DuringVariant,
        userName: String = "재원",
        remainingQuestionCount: Int = 2,
        step: Step = .status
    ) {
        self.variant = variant
        self.userName = userName
        self.remainingQuestionCount = remainingQuestionCount
        self._step = State(initialValue: step)
    }

    var body: some View {
        ZStack {
            headline
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // @ds(layout): +20 — 카드 세로 중심이 화면 중앙보다 20 아래 (시안 top calc(50%+20px))
            card
                .offset(y: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { HomeGreenBackdrop().ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomButtons }
        // @ds(component): top-bar px20/py9 h44 → HilitNavigationBar(h54) — 시안보다 10 높다. 타이틀 비어 있어 nil
        .hilitNavigationBar(background: .filled, onClose: handleClose)
    }

    // MARK: - 섹션

    private var headline: some View {
        Text(copy.headline)
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            // 시안 blend mode color-burn — 그린 스트라이프 위에서 글자가 배경을 태워 짙은 초록으로 보인다.
            .blendMode(.colorBurn)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(spacing): 54 — top-bar 하단(87)에서 헤드라인(top 141)까지 (spacing 토큰은 4~24 뿐)
            .padding(.top, 54)
    }

    /// 시안 «home modal» — 공용 `Modal` 을 쓰지 않는다: 판 패딩 24(모달은 py40)·간격 12(모달은 20)이고
    /// 서브텍스트가 제목 **위**에 오며(모달은 아래) 하단 버튼 슬롯이 없다(버튼은 화면 하단).
    // @ds(component): home modal — 흰 판 p24·gap12 + 일러스트 74 + 서브/제목 역순 + 안내줄. 공용 컴포넌트 없음
    private var card: some View {
        VStack(spacing: .ds(.p12)) {
            // 일러스트는 디자인된 74pt 그대로 — `.frame` 으로 늘리지 않는다(design/image.md).
            Image.Img.oppEllipsis
            VStack(spacing: .ds(.p4)) {
                Text(copy.cardSubText)
                    .dsTypography(.body6)
                    .foregroundStyle(Color.GrayScale.g500)
                Text(copy.cardTitle)
                    .dsTypography(.sub4)
                    .foregroundStyle(Color.HilitBlack.b800)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            if let info = copy.cardInfo {
                InfoField(info)
            }
        }
        .padding(.ds(.p24))
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
        // 시안 카드 폭 327 = 화면 375 − 좌우 24
        .padding(.horizontal, .ds(.p24))
    }

    @ViewBuilder
    private var bottomButtons: some View {
        if let buttons = copy.buttons {
            ButtonLarge(.bottom, tone: .dark) {
                Button(buttons.leading) { handleLeadingButton() }
            } trailing: {
                Button(buttons.trailing) { handleTrailingButton() }
            }
        }
    }

    // MARK: - 문구

    /// 시안별 문구 묶음 — 골격은 하나고 텍스트·유무만 갈린다.
    private struct Copy {
        let headline: String
        let cardSubText: String
        let cardTitle: String
        var cardInfo: String?
        var buttons: (leading: String, trailing: String)?
    }

    private var copy: Copy {
        switch (variant, step) {
        case (_, .restartConfirmation):
            Copy(
                headline: "처음부터\n시작하시겠어요?",
                cardSubText: "처음부터 시작하면",
                cardTitle: "지금까지 진행한 면접 내용으로\n레포트가 제작돼요",
                cardInfo: "이용권이 하나 차감됩니다.",
                buttons: (leading: "뒤로가기", trailing: "처음부터 시작")
            )
        case (.inProgress, .status):
            Copy(
                headline: "\(userName)님,\n진행 중인\n면접이 있어요",
                cardSubText: "면접 상태",
                cardTitle: "\(remainingQuestionCount)개의 질문이 남았어요",
                buttons: (leading: "처음부터 시작", trailing: "이어서 진행")
            )
        case (.reportGenerating, .status):
            // TODO: 시안 미수령 — 문구·CTA 확정 후 교체 (docs/work/home-account.md §3 «레포트 제작 시점»).
            Copy(
                headline: "면접 내용으로\n레포트를\n만들고 있어요",
                cardSubText: "면접 상태",
                cardTitle: "레포트 제작 중"
            )
        }
    }

    // MARK: - 인터랙션 (리듀서 액션 대기)

    private func handleClose() {
        // TODO: `userTappedCloseDuringInterview` — 홈 기본 phase 복귀. 지금은 내비바 기본 동작(dismiss).
    }

    private func handleLeadingButton() {
        switch step {
        case .status:
            // TODO: `userTappedRestartInterview` — 되묻기 표출을 State 가 소유하게 되면 send 로 교체.
            step = .restartConfirmation
        case .restartConfirmation:
            // TODO: `userTappedBackFromRestartConfirmation`.
            step = .status
        }
    }

    private func handleTrailingButton() {
        switch step {
        case .status:
            // TODO: `userTappedResumeInterview` — 같은 session_id 로 면접 복귀(delegate, cross-feature).
            break
        case .restartConfirmation:
            // TODO: `userTappedConfirmRestart` — 이용권 1 차감 + 부분 레포트 제작 후 새 세션.
            break
        }
    }
}

// MARK: - 배경

/// 홈 그린 배경 — g500 판 위 세로 스트라이프 8줄(줄마다 다른 흰색 그라데이션 + 0.2 흰 테두리).
/// 홈 프레임 4종이 공유하는 배경이라 **공용 승격 후보** — 지금은 이 파일 private.
// @ds(component): 그린 스트라이프 배경 (그라데이션 stop 8종 + 0.2 테두리) — 공용 컴포넌트 없음
private struct HomeGreenBackdrop: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.stripes.indices, id: \.self) { index in
                LinearGradient(
                    stops: Self.stripes[index].map {
                        Gradient.Stop(color: Color.BlackWhite.white.opacity($0.opacity), location: $0.location)
                    },
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay {
                    // @ds(spacing): 0.2 — 스트라이프 테두리 두께 (DSOutline 최소가 1)
                    Rectangle().strokeBorder(Color.BlackWhite.white, lineWidth: 0.2)
                }
            }
        }
        .background(Color.HilitGreen.g500)
    }

    /// 스트라이프별 흰색 그라데이션 stop — 시안 8줄이 각기 다른 곡선이라 수치를 그대로 보존한다.
    /// 폭은 시안 46.875(= 375/8)를 고정하지 않고 8등분으로 둔다(기기 폭 대응).
    // @ds(color): white 0.1~0.4 stop 8종 — 스트라이프 그라데이션. 팔레트에 알파 단계 없음
    private static let stripes: [[(location: CGFloat, opacity: Double)]] = [
        [(0.13556, 1), (0.32461, 0.4), (0.99998, 1)],
        [(0.11453, 1), (0.25734, 0.4), (0.47496, 0.3), (0.58866, 0.4), (1, 1)],
        [(0.11788, 1), (0.23104, 0.4), (0.39393, 0.2), (0.504, 0.1), (0.68435, 0.4), (1, 1)],
        [(0.117, 1), (0.23357, 0.3), (0.31717, 0.1), (0.39739, 0.1), (0.68805, 0.3), (1, 1)],
        [(0.13308, 1), (0.24422, 0.3), (0.39291, 0.1), (0.50844, 0.1), (0.62571, 0.3), (1, 1)],
        [(0.1221, 1), (0.2742, 0.4), (0.37483, 0.2), (0.5122, 0.1), (0.68957, 0.4), (1, 1)],
        [(0.14222, 1), (0.32786, 0.4), (0.42853, 0.3), (0.5898, 0.4), (1, 1)],
        [(0.14044, 1), (0.51272, 0.4), (0.99998, 1)]
    ]
}

#Preview("진행 중인 면접 있음 — 3756:10788") {
    HomeDuringInterviewView(variant: .inProgress)
}

#Preview("처음부터 시작 되묻기 — 3632:10935") {
    HomeDuringInterviewView(variant: .inProgress, step: .restartConfirmation)
}

#Preview("레포트 제작 중 — 시안 미수령") {
    HomeDuringInterviewView(variant: .reportGenerating)
}
