//
//  ActivityFeature.swift
//  ActivityFeature
//
//  Created by EunseoKim on 5/27/26.
//

import ComposableArchitecture
import Foundation

/// 활동/알림 목록 화면.
///
/// 빈 상태 + 더미 리스트를 보여주는 학습용 Feature. List/Detail 같은
/// 분기 없이 단일 화면으로 유지한다.
@Reducer
public struct ActivityFeature {
    @ObservableState
    public struct State: Equatable {
        public var items: [ActivityItem]

        public init(items: [ActivityItem] = ActivityItem.samples) {
            self.items = items
        }
    }

    public enum Action {
        case clearAllTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .clearAllTapped:
                state.items = []
                return .none
            }
        }
    }
}

public struct ActivityItem: Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let subtitle: String

    public init(id: Int, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }

    public static let samples: [ActivityItem] = [
        .init(id: 1, title: "Ada followed you", subtitle: "방금 전"),
        .init(id: 2, title: "Alan liked your post", subtitle: "5분 전"),
        .init(id: 3, title: "Grace commented on your photo", subtitle: "1시간 전")
    ]
}
