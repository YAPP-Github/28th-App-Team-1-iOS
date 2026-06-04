//
//  ActivityItem.swift
//  Models
//

import Foundation

/// 활동/알림 피드 항목.
public struct ActivityItem: Equatable, Identifiable, Codable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String

    public init(id: Int, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

extension ActivityItem {
    /// mock 샘플 데이터. live/preview client 가 공통으로 사용한다.
    public static let samples: [ActivityItem] = [
        .init(id: 1, title: "Ada followed you", subtitle: "방금 전"),
        .init(id: 2, title: "Alan liked your post", subtitle: "5분 전"),
        .init(id: 3, title: "Grace commented on your photo", subtitle: "1시간 전")
    ]
}
