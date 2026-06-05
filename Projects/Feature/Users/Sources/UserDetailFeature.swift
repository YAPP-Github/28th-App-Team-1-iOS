//
//  UserDetailFeature.swift
//  UserFeature
//

import ComposableArchitecture
import Foundation
import Models
import UserClientInterface

/// 사용자 상세 화면 Reducer.
// @lat: [[users#User Detail]]
// depends-on: [[profile#Save]]  ← "편집" 탭 시 delegate(.editProfileTapped). Profile 을 직접 import 하지 않음.
@Reducer
public struct UserDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var isLoading: Bool
        public var errorMessage: String?

        public init(user: User, isLoading: Bool = false, errorMessage: String? = nil) {
            self.user = user
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action {
        case onAppear
        case onDisappear
        case userTappedEditButton
        case userDetailLoaded(User)
        case userLoadingFailed(String)
        case alertDismissed
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case editProfileTapped(id: Int)
        }
    }

    @Dependency(\.userClient) var userClient

    private enum CancelID { case load }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [id = state.user.id] send in
                    do {
                        let user = try await userClient.fetchUser(id)
                        await send(.userDetailLoaded(user))
                    } catch {
                        await send(.userLoadingFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.load)

            case .onDisappear:
                return .cancel(id: CancelID.load)

            case let .userDetailLoaded(user):
                state.isLoading = false
                state.user.bio = user.bio
                return .none

            case let .userLoadingFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .userTappedEditButton:
                return .send(.delegate(.editProfileTapped(id: state.user.id)))

            case .alertDismissed:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
