//
//  MyPageViewPreviews.swift
//  FeatureMyPage
//
//  Created by 서정원 on 26/08/01.
//

// Figma «[Part5] 마이페이지» 의 화면 6장을 상태별 캔버스로 되살린다 — 시안과 나란히 놓고 대조하는 용도.

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

#Preview("Default — 포트폴리오 등록됨") {
    MyPageView(
        store: Store(initialState: MyPageFeature.State()) {
            MyPageFeature()
        }
    )
}

#Preview("업로드 전") {
    MyPageView(
        store: Store(initialState: MyPageFeature.State(portfolio: .empty)) {
            MyPageFeature()
        }
    )
}

#Preview("업로드 중") {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(
                portfolio: .uploading(.placeholder, progress: 0.2)
            )
        ) {
            MyPageFeature()
        }
    )
}

#Preview("업로드 완료") {
    MyPageView(
        store: Store(initialState: MyPageFeature.State(portfolio: .uploaded(.placeholder))) {
            MyPageFeature()
        }
    )
}

#Preview("업로드 실패 — 툴팁") {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(
                portfolio: .failed(.placeholder),
                isPortfolioTooltipPresented: true
            )
        ) {
            MyPageFeature()
        }
    )
}

#Preview("레포트 펼침") {
    MyPageView(
        store: Store(initialState: MyPageFeature.State(expandedReportID: "report-normal")) {
            MyPageFeature()
        }
    )
}

#Preview("모달 — 포트폴리오 삭제") {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(presentedModal: .deleteConfirm(remaining: 1))
        ) {
            MyPageFeature()
        }
    )
}

#Preview("모달 — 삭제 불가") {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(presentedModal: .deleteBlocked(remaining: nil))
        ) {
            MyPageFeature()
        }
    )
}

#Preview("모달 — 새로 업로드") {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(presentedModal: .replaceConfirm(remaining: 1))
        ) {
            MyPageFeature()
        }
    )
}

#Preview("모달 — 업로드 불가") {
    MyPageView(
        store: Store(
            initialState: MyPageFeature.State(presentedModal: .replaceBlocked(remaining: 0))
        ) {
            MyPageFeature()
        }
    )
}

#Preview("모달 — 로딩") {
    MyPageView(
        store: Store(initialState: MyPageFeature.State(presentedModal: .loading)) {
            MyPageFeature()
        }
    )
}
