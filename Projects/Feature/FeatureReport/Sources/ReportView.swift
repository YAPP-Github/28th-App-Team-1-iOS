//
//  ReportView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import SwiftUI

/// AI 면접 리포트 진입점. 루트(리포트 메인) + 이후 화면 스택을 NavigationStack 으로 렌더한다.
/// 부모는 이 뷰만 제시하면 되고, 화면 전환은 코디네이터(ReportFeature)가 담당한다.
public struct ReportView: View {
    @Bindable public var store: StoreOf<ReportFeature>

    public init(store: StoreOf<ReportFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            ReportMainView(
                store: store.scope(state: \.main, action: \.main)
            )
        } destination: { store in
            switch store.case {
            case let .videoPlayer(store):
                ReportVideoPlayerView(store: store)
            case let .feedback(store):
                ReportFeedbackView(store: store)
            case let .final(store):
                ReportFinalView(store: store)
            }
        }
    }
}

#Preview("리포트 플로우") {
    ReportView(
        store: Store(initialState: ReportFeature.State()) {
            ReportFeature()
        }
    )
}
