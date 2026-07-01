//
//  FeatureReelsTests.swift
//  FeatureReelsTests
//
//  Created by EunSeo on 26/07/02.
//

import ComposableArchitecture
import XCTest

import FeatureReelsImplementation

// 이산 상태 전이만 검증한다. 연속 드래그/스케일 애니메이션은 View-local State 라 테스트 대상이 아니다.
@MainActor
final class FeatureReelsTests: XCTestCase {
    func test_userTappedCommentButton_presentsComments() async {
        let store = TestStore(initialState: .sample()) {
            ReelsFeature()
        }

        await store.send(.userTappedCommentButton) {
            $0.isCommentsPresented = true
        }
    }

    func test_userTappedSendComment_insertsCommentAndClearsDraft() async {
        let store = TestStore(initialState: .sample()) {
            ReelsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        await store.send(.binding(.set(\.draftComment, "새 댓글"))) {
            $0.draftComment = "새 댓글"
        }

        await store.send(.userTappedSendComment) {
            $0.comments.insert(
                Comment(id: UUID(0), authorName: "me", text: "새 댓글", createdAgo: "방금"),
                at: 0
            )
            $0.reel.commentCount = $0.comments.count
            $0.draftComment = ""
        }
    }

    func test_userTappedSendComment_ignoresBlankDraft() async {
        let store = TestStore(initialState: .sample()) {
            ReelsFeature()
        }

        await store.send(.binding(.set(\.draftComment, "   "))) {
            $0.draftComment = "   "
        }
        // 공백뿐이면 상태 변화 없음 (기대 클로저 없음).
        await store.send(.userTappedSendComment)
    }

    func test_commentsDismissed_hidesComments() async {
        let store = TestStore(initialState: .sample(isPresented: true)) {
            ReelsFeature()
        }

        await store.send(.commentsDismissed) {
            $0.isCommentsPresented = false
        }
    }
}

private extension ReelsFeature.State {
    static func sample(isPresented: Bool) -> Self {
        var state = ReelsFeature.State.sample()
        state.isCommentsPresented = isPresented
        return state
    }
}
