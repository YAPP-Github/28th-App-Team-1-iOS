//
//  UsersFeature.swift
//  UsersFeature
//

import ComposableArchitecture
import Foundation
import Models

/// User 도메인의 List → Detail 흐름 컨테이너.
///
/// Profile 편집 같은 cross-feature 전환은 직접 처리하지 않고
/// `delegate(.editProfile)` 로 상위(코디네이터)에 위임한다 — Feature 간 의존 0.
@Reducer
public struct UsersFeature {
    @ObservableState
    public struct State: Equatable {
        public var list: UserListFeature.State
        public var path: StackState<Path.State>

        public init(
            list: UserListFeature.State = .init(),
            path: StackState<Path.State> = .init()
        ) {
            self.list = list
            self.path = path
        }
    }

    public enum Action {
        case list(UserListFeature.Action)
        case path(StackActionOf<Path>)
        /// 코디네이터가 프로필 저장 결과를 통보 — list/detail 을 직접 갱신한다.
        case profileUpdated(Profile)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            /// 사용자가 상세 화면에서 프로필 편집을 요청 — 코디네이터가 앱 레벨에서 제시한다.
            case editProfile(id: Int)
        }
    }

    /// 이 도메인 안에서 푸시 가능한 화면의 합집합.
    @Reducer
    public enum Path {
        case detail(UserDetailFeature)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.list, action: \.list) {
            UserListFeature()
        }
        Reduce { state, action in
            switch action {
            case let .list(.delegate(.userTappedRow(user))):
                state.path.append(.detail(UserDetailFeature.State(user: user)))
                return .none

            case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
                return .send(.delegate(.editProfile(id: id)))

            case let .profileUpdated(profile):
                applyProfileUpdate(profile, to: &state)
                return .none

            case .list, .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    /// 저장된 프로필을 목록 항목과 열려 있는 상세 화면에 반영.
    private func applyProfileUpdate(_ profile: Profile, to state: inout State) {
        if let index = state.list.users.firstIndex(where: { $0.id == profile.id }) {
            state.list.users[index].name = profile.displayName
            state.list.users[index].bio = profile.bio
        }
        for id in state.path.ids {
            guard case .detail(var detail) = state.path[id: id], detail.user.id == profile.id else {
                continue
            }
            detail.user.name = profile.displayName
            detail.user.bio = profile.bio
            state.path[id: id] = .detail(detail)
        }
    }
}

extension UsersFeature.Path.State: Equatable {}
