//
//  UserListFeature.swift
//  UserFeature
//

import ComposableArchitecture
import Foundation
import Models
import UserClientInterface

/// 사용자 목록 화면 Reducer.
@Reducer
public struct UserListFeature {
    @ObservableState
    public struct State: Equatable {
        public var users: [User]
        public var isLoading: Bool
        public var errorMessage: String?

        public init(
            users: [User] = [],
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.users = users
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action {
        case onAppear
        case onDisappear
        case userTappedRow(User)
        case usersLoaded([User])
        case userLoadingFailed(String)
        case alertDismissed
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case userTappedRow(User)
        }
    }

    @Dependency(\.userClient) var userClient

    private enum CancelID { case load }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.users.isEmpty, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let users = try await userClient.fetchUsers()
                        await send(.usersLoaded(users))
                    } catch {
                        await send(.userLoadingFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.load)

            case .onDisappear:
                return .cancel(id: CancelID.load)

            case let .usersLoaded(users):
                state.isLoading = false
                state.users = users
                return .none

            case let .userLoadingFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .userTappedRow(user):
                return .send(.delegate(.userTappedRow(user)))

            case .alertDismissed:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
