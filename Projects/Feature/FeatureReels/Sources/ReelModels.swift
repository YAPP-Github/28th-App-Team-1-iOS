//
//  ReelModels.swift
//  FeatureReels
//
//  Created by EunSeo on 26/07/02.
//

import Foundation

// 예시용 로컬 모델. 실데이터로 승격 시 DomainReels 모듈로 분리한다.

public struct Reel: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var videoURL: URL?
    public var authorName: String
    public var caption: String
    public var likeCount: Int
    public var commentCount: Int

    public init(
        id: UUID = UUID(),
        videoURL: URL? = nil,
        authorName: String,
        caption: String,
        likeCount: Int,
        commentCount: Int
    ) {
        self.id = id
        self.videoURL = videoURL
        self.authorName = authorName
        self.caption = caption
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}

public struct Comment: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var authorName: String
    public var text: String
    public var likeCount: Int
    public var createdAgo: String

    public init(
        id: UUID = UUID(),
        authorName: String,
        text: String,
        likeCount: Int = 0,
        createdAgo: String
    ) {
        self.id = id
        self.authorName = authorName
        self.text = text
        self.likeCount = likeCount
        self.createdAgo = createdAgo
    }
}

public extension Reel {
    static func sample(videoURL: URL? = nil) -> Reel {
        Reel(
            videoURL: videoURL,
            authorName: "yapp_official",
            caption: "릴스 댓글 시트 예시 — 댓글을 올리면 영상이 비율대로 축소됩니다.",
            likeCount: 1234,
            commentCount: Comment.samples.count
        )
    }
}

public extension Comment {
    static let samples: [Comment] = [
        Comment(authorName: "swiftui_dev", text: "이 인터랙션 어떻게 만든 거예요? 👀", likeCount: 42, createdAgo: "2시간"),
        Comment(authorName: "tca_fan", text: "연속 드래그를 View-local State 로 뺀 게 포인트", likeCount: 18, createdAgo: "1시간"),
        Comment(authorName: "reels_lover", text: "영상이 자연스럽게 줄어드네요", likeCount: 7, createdAgo: "58분"),
        Comment(authorName: "designer_kim", text: "코너 라운딩까지 디테일 좋아요", likeCount: 3, createdAgo: "30분"),
        Comment(authorName: "ios_newbie", text: "예시 앱으로 돌려봤는데 부드러워요", likeCount: 1, createdAgo: "12분")
    ]
}
