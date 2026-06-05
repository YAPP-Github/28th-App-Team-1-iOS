//
//  ActivityFeature.swift
//  ActivityFeature
//

import ActivityClientInterface
import ComposableArchitecture
import Foundation
import Models

/// 활동/알림 목록 화면. `ActivityClient` 로 항목을 로드/초기화한다.
@Reducer
public struct ActivityFeature {
    @ObservableState
    public struct State: Equatable {
        public var items: [ActivityItem]
        public var isLoading: Bool
        public var errorMessage: String?

        public init(
            items: [ActivityItem] = [],
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.items = items
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action {
        case onAppear
        case onDisappear
        case clearAllTapped
        case activitiesLoaded([ActivityItem])
        case activitiesLoadingFailed(String)
        case clearedAll
        case alertDismissed
    }

    @Dependency(\.activityClient) var activityClient

    private enum CancelID { case load }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.items.isEmpty, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let items = try await activityClient.fetchActivities()
                        await send(.activitiesLoaded(items))
                    } catch {
                        await send(.activitiesLoadingFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.load)

            case .onDisappear:
                return .cancel(id: CancelID.load)

            case let .activitiesLoaded(items):
                state.isLoading = false
                state.items = items
                return .none

            case let .activitiesLoadingFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .clearAllTapped:
                return .run { send in
                    try await activityClient.clearAll()
                    await send(.clearedAll)
                }

            case .clearedAll:
                state.items = []
                return .none

            case .alertDismissed:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
