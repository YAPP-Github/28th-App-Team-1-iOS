//
//  Interview.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/07.
//

import Foundation

/// 면접 세션 요약 — 목록·상세 진입의 최소 단위.
public struct Interview: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let createdAt: Date

    public init(id: String, title: String, createdAt: Date) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}

public extension Interview {
    /// Preview(`previewValue`)·mock 공용 샘플.
    static let previews: [Interview] = [
        Interview(
            id: "interview-1",
            title: "iOS 직무 면접 연습",
            createdAt: Date(timeIntervalSince1970: 1_750_000_000)
        ),
        Interview(
            id: "interview-2",
            title: "프로젝트 경험 꼬리질문 대비",
            createdAt: Date(timeIntervalSince1970: 1_750_086_400)
        )
    ]
}
