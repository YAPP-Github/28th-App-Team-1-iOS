//
//  ReportHighlightDetailView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

// 하이라이트 상세 바텀시트. 레포 최초의 `.sheet` 도입 지점이라 여기서 패턴을 정한다 —
// 부모가 `.sheet(item:)` 으로 제시하고, 이 뷰는 detent 만 지정한다.
// depth 1(진단) → depth 2(다음 대비) 순서. 재료가 없는 블록은 렌더하지 않는다.
@ViewAction(for: ReportHighlightDetailFeature.self)
public struct ReportHighlightDetailView: View {
    @Bindable public var store: StoreOf<ReportHighlightDetailFeature>

    public init(store: StoreOf<ReportHighlightDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                diagnosis
                if store.isVideoJumpVisible {
                    PrimaryButton("이 장면 영상으로 보기") { send(.userTappedVideoJump) }
                }
                nextPreparation
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.ds(.p20))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background(Color.BlackWhite.white)
        .onAppear { send(.onAppear) }
    }

    // MARK: - depth 1 진단

    private var diagnosis: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 행동형 키워드 태그 — 서버 확장 전에는 없어서 숨는다.
            if let keyword = store.context.keyword {
                TagLabel(keyword)
            }
            Text(store.context.sentence)
                .dsTypography(.sub7)
                .foregroundStyle(toneColor)
                .fixedSize(horizontal: false, vertical: true)
            if let analysis = store.context.analysis {
                Text(analysis)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.Gray.g600)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - depth 2 다음 대비

    @ViewBuilder
    private var nextPreparation: some View {
        if store.hasFollowUpQuestions {
            VStack(alignment: .leading, spacing: 8) {
                Text("다음 대비")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.Gray.g800)
                ForEach(Array(store.context.followUpQuestions.enumerated()), id: \.offset) { _, question in
                    Text(question)
                        .dsTypography(.body3)
                        .foregroundStyle(Color.Gray.g600)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else if let closingMessage = store.closingMessage {
            Text(closingMessage)
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g600)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var toneColor: Color {
        switch store.context.tone {
        case .good: Color.Positive.p800
        case .improve: Color.Error.e500
        case .unknown: Color.Gray.g800
        }
    }
}

#Preview("상세 시트 — 개선") {
    ReportHighlightDetailView(
        store: Store(
            initialState: ReportHighlightDetailFeature.State(
                context: HighlightContext(
                    sentence: "결제가 느려서 캐시를 써서 빠르게 만들었어요.",
                    tone: .improve,
                    analysis: "왜 그 방법이 통했는지 원인이 빠졌어요."
                ),
                showsVideoJump: false
            )
        ) {
            ReportHighlightDetailFeature()
        }
    )
}
