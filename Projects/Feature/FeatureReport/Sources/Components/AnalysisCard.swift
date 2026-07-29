//
//  AnalysisCard.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// AI 분석 말풍선 카드 — Figma «message-card»(size=detail / size=mini).
///
/// detail 은 아이콘 + 라벨 + 분석 본문, mini 는 한 줄 코칭 문구다.
/// Figma 의 볼드 한 줄(«구체적인 사례 제시» 등)에 대응하는 서버 필드가 아직 없어
/// `title` 이 nil 이면 그 줄만 빼고 렌더한다 — 필드가 생기면 값만 넘기면 된다.
struct AnalysisCard: View {
    enum Kind {
        /// 질문 의도 분석 — 그린 반짝임.
        case question
        /// 잘한 답변 — 그린 체크.
        case strength
        /// 개선할 답변 — 레드 느낌표.
        case improvement

        var icon: Image {
            switch self {
            case .question: Image.Analyze.question
            case .strength: Image.Analyze.success
            case .improvement: Image.Analyze.problem
            }
        }

        /// 카드 종류 라벨 — 클라 소유 고정 문구. 종류에서 결정되므로 호출부가 넘기지 않는다.
        var label: String {
            switch self {
            case .question: "Hilit의 질문 분석"
            case .strength, .improvement: "Hilit의 답변 분석"
            }
        }
    }

    let kind: Kind
    /// 분석 제목 — 서버 확장 전에는 nil 이라 렌더하지 않는다.
    var title: String?
    /// 분석 본문 (서버 소유 문구).
    let contents: String

    var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            HStack(spacing: .ds(.p8)) {
                kind.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.label)
                        .dsTypography(.body9)
                        .foregroundStyle(Color.GrayScale.g400)
                    if let title {
                        Text(title)
                            .dsTypography(.body1)
                            .foregroundStyle(Color.BlackWhite.white)
                    }
                }
                Spacer(minLength: 0)
            }

            Text(contents)
                .dsTypography(.body7)
                .foregroundStyle(Color.GrayScale.g200)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.HilitBlack.b800)
    }
}

/// 한 줄 코칭 문구 카드 — Figma «message-card»(size=mini). 시트 맨 아래 마무리 자리.
struct AnalysisTipCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: .ds(.p8)) {
            Image.Ai.green16
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                // body7 첫 줄 중앙에 맞춘다 — 아이콘은 캡 높이 기준으로 살짝 내려야 나란해 보인다.
                .padding(.top, 2)

            Text(message)
                .dsTypography(.body7)
                .foregroundStyle(Color.BlackWhite.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.GrayScale.g800)
    }
}

#Preview("분석 카드") {
    VStack(spacing: .ds(.p16)) {
        AnalysisCard(
            kind: .question,
            contents: "트래픽이 증가했을 때 발생할 병목 지점과 시스템의 한계, 그리고 이를 어떻게 판단할지 설명하는 질문입니다."
        )
        AnalysisCard(
            kind: .strength,
            title: "명확한 원인과 구조 설명",
            contents: "문제를 바라보는 관점이 좋았어요. 원인과 한계까지 함께 설명해 설득력이 높았습니다."
        )
        AnalysisCard(
            kind: .improvement,
            contents: "해결 방법만으로는 설득력이 부족합니다. 왜 그 방법을 선택했는지 근거를 덧붙여 보세요."
        )
        AnalysisTipCard(message: "질문의 의도를 떠올리며 답변을 준비해 보세요!")
    }
    .padding(.ds(.p20))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.HilitBlack.b900)
}
