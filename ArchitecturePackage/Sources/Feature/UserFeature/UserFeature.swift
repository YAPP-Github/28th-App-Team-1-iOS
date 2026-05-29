//
//  UserFeature.swift
//  UserFeature
//
//  Created by EunseoKim on 5/27/26.
//

import ComposableArchitecture
import Foundation
import Models
import ProfileFeature

/// User 도메인의 List → Detail → Profile 편집 흐름을 한 곳에서 조율하는 Reducer.
///
/// 기존 `AppFeature` 가 들고 있던 user 관련 navigation 책임을 흡수해
/// 탭별로 독립된 NavigationStack 을 가질 수 있도록 캡슐화한 컨테이너.
@Reducer
public struct UserFeature {
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
    }

    /// 푸시 가능한 모든 화면의 합집합.
    @Reducer
    public enum Path {
        case detail(UserDetailFeature)
        case profile(ProfileFeature)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.list, action: \.list) {
            UserListFeature()
        }
        Reduce { state, action in
            switch action {
            // List 행 탭 → Detail push (Case B: User 객체째)
            case let .list(.delegate(.userTappedRow(user))):
                state.path.append(.detail(UserDetailFeature.State(user: user)))
                return .none

            // Detail 의 Edit Profile → Profile push (Case A: id 만)
            case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
                state.path.append(.profile(ProfileFeature.State(profileId: id)))
                return .none

            // Profile 저장 → 목록·상세 갱신 + pop (Case C: 결과 객체)
            case let .path(.element(id: _, action: .profile(.delegate(.profileSaved(profile))))):
                applyProfileUpdate(profile, to: &state)
                if !state.path.isEmpty {
                    state.path.removeLast()
                }
                return .none

            case .list, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    /// 저장된 `Profile` 을 목록과 스택의 상세 양쪽에 반영.
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

extension UserFeature.Path.State: Equatable {}
