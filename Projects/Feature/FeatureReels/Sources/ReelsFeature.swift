//
//  ReelsFeature.swift
//  FeatureReels
//
//  Created by EunSeo on 26/07/02.
//

import ComposableArchitecture
import Foundation

// @lat: [[reels]]
//
// 이산 상태만 여기(Reducer)에 둔다: 열림/닫힘·댓글 목록·입력값·재생.
// 시트 드래그 진행률(60~120fps 연속값)은 View-local @State 로 두고 Reducer 로 방출하지 않는다.
// 둘의 다리 = ReelsView 의 .onChange(of: store.isCommentsPresented).
@Reducer
public struct ReelsFeature {
    @ObservableState
    public struct State: Equatable {
        public var reel: Reel
        public var comments: [Comment]
        public var isCommentsPresented: Bool
        public var draftComment: String
        public var isPlaying: Bool

        public init(
            reel: Reel,
            comments: [Comment] = Comment.samples,
            isCommentsPresented: Bool = false,
            draftComment: String = "",
            isPlaying: Bool = true
        ) {
            self.reel = reel
            self.comments = comments
            self.isCommentsPresented = isCommentsPresented
            self.draftComment = draftComment
            self.isPlaying = isPlaying
        }

        // Example 은 videoURL 만 주입한다.
        public static func sample(videoURL: URL? = nil) -> State {
            State(reel: .sample(videoURL: videoURL))
        }
    }

    public enum Action: BindableAction {
        case onAppear
        case userTappedVideo
        case userTappedCommentButton
        case userTappedCloseComments
        case userTappedSendComment
        case commentsDismissed
        case binding(BindingAction<State>)
    }

    public init() {}

    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case .userTappedVideo:
                state.isPlaying.toggle()
                return .none

            case .userTappedCommentButton:
                state.isCommentsPresented = true
                return .none

            case .userTappedCloseComments:
                state.isCommentsPresented = false
                return .none

            case .userTappedSendComment:
                let text = state.draftComment.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return .none }
                state.comments.insert(
                    Comment(id: uuid(), authorName: "me", text: text, createdAgo: "방금"),
                    at: 0
                )
                state.reel.commentCount = state.comments.count
                state.draftComment = ""
                return .none

            case .commentsDismissed:
                state.isCommentsPresented = false
                return .none

            case .binding:
                return .none
            }
        }
    }
}
