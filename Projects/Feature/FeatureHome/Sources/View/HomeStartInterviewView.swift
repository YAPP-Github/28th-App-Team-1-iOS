//
//  HomeStartInterviewView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_StartInterview»             https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-1612
//        «Home_StartInterview_SameContext» https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-13730
//        «Home_StartInterview_TrialEnded»  https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-9566

import SharedDesignSystemInterface
import SwiftUI

/// 면접 시작 — 시안 3장을 `HomeFeature.StartVariant` 로 분기한다.
///
/// 세 시안의 골격은 같다: 커튼 그린 배경 + 좌상단 인사말(color-burn) + 중앙 흰 카드 + 하단 CTA.
/// 갈리는 건 **인사말 문구 · 카드 내용 · CTA** 셋이고, 닫기(X) 내비바는 소진 시안에만 없다
/// (그 화면의 나가기는 하단 «홈으로» 가 맡는다).
///
/// 카드 안 값(잔여 횟수·포트폴리오 파일 정보)과 버튼 액션은 아직 자리만 잡아 뒀다 —
/// 리듀서에 State·Action 이 생기면 `TODO` 자리를 교체한다.
struct HomeStartInterviewView: View {
    let variant: HomeFeature.StartVariant

    var body: some View {
        if showsCloseBar {
            screen
                // TODO: X = «면접 시작 취소 → 홈 기본» — 리듀서에 userTappedClose 가 생기면 onClose 로 넘긴다.
                //       그때까지는 내비바 기본 동작(dismiss)에 맡긴다.
                .hilitNavigationBar(background: .filled)
        } else {
            screen
        }
    }

    private var screen: some View {
        ZStack {
            curtainBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                greeting
                    .padding(.top, greetingTopPadding)
                    // @ds(spacing): 80 — 인사말 아래 ~ 카드 위 (시안 텍스트 bottom 255 → 카드 top 335). spacing 토큰은 4~24
                    .padding(.bottom, 80)
                card
                Spacer(minLength: 0)
                callToAction
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // 인사말의 colorBurn 이 «배경 커튼까지만» 섞이도록 합성 경계를 여기서 닫는다.
        .compositingGroup()
    }

    // MARK: - 인사말

    private var greeting: some View {
        // TODO: 이름은 서버 프로필(nickname) — State 에 값이 생기면 교체 (필요한 State: userName).
        Text(greetingText)
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(component): mix-blend-mode color-burn — 인사말이 배경 커튼과 타서 초록으로 보이는 효과. DS 에 블렌드 규칙 없음
            .blendMode(.colorBurn)
    }

    /// 시안의 줄바꿈을 그대로 옮긴다 — 세 시안 모두 3줄 고정 폭에 맞춰 끊어져 있다.
    private var greetingText: String {
        switch variant {
        case .first: "재원님,\n지금부터 면접을\n시작해 볼까요?"
        case .hasPortfolio: "이전과\n동일한 정보로\n시작할까요?"
        case .exhausted: "재원님,\n무료 횟수를 모두\n사용했어요"
        }
    }

    /// 인사말 top — 시안은 세 장 모두 프레임 top 141 이다. 닫기 바가 있는 시안은 그 높이(DS 54)만큼
    /// 콘텐츠가 이미 내려와 있고, 없는 시안은 상태바(시안 43)만 빠진다.
    // @ds(spacing): 141 → 44 / 98 — 인사말 top (spacing 토큰은 4~24)
    private var greetingTopPadding: CGFloat { showsCloseBar ? 44 : 98 }

    /// 닫기(X) 내비바 유무 — 소진 시안(3632:9566)엔 top-bar 자체가 없다.
    private var showsCloseBar: Bool {
        switch variant {
        case .first, .hasPortfolio: true
        case .exhausted: false
        }
    }

    // MARK: - 카드

    @ViewBuilder private var card: some View {
        switch variant {
        case .first:
            // TODO: «3회» 는 서버 잔여 횟수 — State 에 값이 생기면 교체 (필요한 State: remainingChances).
            remainingChancesCard(icon: Image.Img.oppO, count: "3회")
        case .hasPortfolio:
            portfolioCard
        case .exhausted:
            remainingChancesCard(icon: Image.Img.oppX, count: "0회")
        }
    }

    /// 잔여 횟수 카드 — Figma «home modal» property1=opp (3632:10988). 일러스트 + 보조문구 + 값.
    /// 시안의 `showInfoField` 축은 두 시안 모두 false 라 안내줄을 두지 않았다.
    private func remainingChancesCard(icon: Image, count: String) -> some View {
        modalCard {
            icon
            VStack(spacing: .ds(.p4)) {
                Text("남은 면접 기회")
                    .dsTypography(.body6)
                    .foregroundStyle(Color.GrayScale.g500)
                Text(count)
                    .dsTypography(.sub4)
                    .foregroundStyle(Color.HilitBlack.b800)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    /// 등록 포트폴리오 카드 — Figma «home modal» property1=port (3632:13862). 제목 + 파일 한 줄.
    private var portfolioCard: some View {
        modalCard {
            Text("등록한 포트폴리오")
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            portfolioFileRow
        }
    }

    /// 파일 한 줄 — Figma «card» 3632:13817. 36 파일 아이콘 + 파일명 + «날짜 | 용량».
    private var portfolioFileRow: some View {
        HStack(spacing: .ds(.p12)) {
            Image.File.green36
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                // TODO: 파일명·업로드일·용량은 등록된 포트폴리오 값 — State 에 값이 생기면 교체
                //       (필요한 State: portfolioFileName / portfolioUploadedAt / portfolioSize).
                Text("{파일명}.pdf")
                    .dsTypography(.body2)
                    .foregroundStyle(Color.GrayScale.g700)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: .ds(.p4)) {
                    Text("{20xx.xx.xx}")
                        .dsTypography(.body10)
                        .foregroundStyle(Color.GrayScale.g400)
                    Rectangle()
                        .fill(Color.GrayScale.g200)
                        .frame(width: .ds(.medium), height: .ds(.p10))
                    Text("{0}mb")
                        .dsTypography(.body10)
                        .foregroundStyle(Color.GrayScale.g400)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.ds(.p14))
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
        .overlay {
            // @ds(spacing): 1.5 (outline-sb) — 파일 카드 테두리 두께 (DSOutline 는 1·1.2·4·6)
            Rectangle()
                .strokeBorder(Color.GrayScale.g100, lineWidth: 1.5)
        }
    }

    /// 흰 카드 판 — Figma «home modal» (p24 · gap12 · 모서리 0 · 폭 327 = 375 − 24×2).
    // @ds(component): «home modal» — DS `Modal`(py40 · gap20 · 제목이 서브텍스트 위)과 리듬이 다른 별개 가족. 공용 컴포넌트 없음
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
        switch variant {
        case .first:
            // TODO: 리듀서에 userTappedStartInterview 가 생기면 send 로 교체 (여기서 정보 입력 플로우로 넘어간다).
            ButtonLarge("시작하기", .bottom) {}
        case .hasPortfolio:
            ButtonLarge(.bottom, tone: .dark) {
                // TODO: userTappedEditInterviewInfo
                Button("수정하기") {}
            } trailing: {
                // TODO: userTappedStartInterview
                Button("시작하기") {}
            }
        case .exhausted:
            // TODO: userTappedBackToHome — phase 를 .default 로 되돌린다.
            ButtonLarge("홈으로", .bottom) {}
        }
    }

    // MARK: - 배경 커튼

    /// 그린 판 위에 세로 밴드 8개(흰 그라데이션)를 겹친 장식 배경 — 위·아래는 흰색으로 덮이고
    /// 가운데 띠만 그린이 비쳐 커튼 주름처럼 보인다. 상단이 흰색이라 내비바(흰 판)와 이음새가 없다.
    // @ds(component): 세로 밴드 8개 × 흰 그라데이션 정지점 — 홈 전용 장식 배경, DS 에 없음
    private var curtainBackground: some View {
        HStack(spacing: 0) {
            ForEach(Self.curtainBands.indices, id: \.self) { index in
                LinearGradient(
                    stops: Self.curtainBands[index].map {
                        Gradient.Stop(color: Color.BlackWhite.white.opacity($0.opacity), location: $0.location)
                    },
                    startPoint: .top,
                    endPoint: .bottom
                )
                // @ds(spacing): 0.2 — 밴드 경계선 두께 (DSOutline 최소가 1)
                .border(Color.BlackWhite.white, width: 0.2)
            }
        }
        .background(Color.HilitGreen.g500)
    }

    /// 밴드별 흰색 정지점 — `location` 은 화면 전체 높이 비율(시안 812pt 기준의 % 를 그대로 옮긴 값)이라
    /// 기기 높이가 달라도 같은 비율로 늘어난다. 밴드마다 정지점이 달라 주름이 불규칙해 보인다.
    private static let curtainBands: [[(opacity: Double, location: CGFloat)]] = [
        [(1, 0.136), (0.4, 0.325), (1, 1)],
        [(1, 0.115), (0.4, 0.257), (0.3, 0.475), (0.4, 0.589), (1, 1)],
        [(1, 0.118), (0.4, 0.231), (0.2, 0.394), (0.1, 0.504), (0.4, 0.684), (1, 1)],
        [(1, 0.117), (0.3, 0.234), (0.1, 0.317), (0.1, 0.397), (0.3, 0.688), (1, 1)],
        [(1, 0.133), (0.3, 0.244), (0.1, 0.393), (0.1, 0.508), (0.3, 0.626), (1, 1)],
        [(1, 0.122), (0.4, 0.274), (0.2, 0.375), (0.1, 0.512), (0.4, 0.690), (1, 1)],
        [(1, 0.142), (0.4, 0.328), (0.3, 0.429), (0.4, 0.590), (1, 1)],
        [(1, 0.140), (0.4, 0.513), (1, 1)]
    ]
}

#Preview("처음 — 정보 입력 전") {
    HomeStartInterviewView(variant: .first)
}

#Preview("이전 정보 재사용") {
    HomeStartInterviewView(variant: .hasPortfolio)
}

#Preview("무료 횟수 소진") {
    HomeStartInterviewView(variant: .exhausted)
}
