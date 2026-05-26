//
//  AppFeature.swift
//  AppFeature
//
//  Created by EunseoKim on 5/26/26.
//

import ComposableArchitecture
import Foundation
import Models
import ProfileFeature
import UserDetailFeature
import UserListFeature

/// 앱 최상위 Reducer 겸 Coordinator.
///
/// - 자식 도메인: `UserListFeature` 한 개를 루트로 보유.
/// - 화면 스택: ``Path-swift.enum`` 으로 정의되며 ``State/path`` 에서 관리.
/// - 화면 전환: View 가 아닌 이 Reducer 가 자식 delegate 를 받아 처리.
///
/// 자세한 절차는 `AddingFeature` 가이드와 `AddingFeatureTutorial` 튜토리얼 참조.
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var userList: UserListFeature.State
        public var path: StackState<Path.State>

        public init(
            userList: UserListFeature.State = .init(),
            path: StackState<Path.State> = .init()
        ) {
            self.userList = userList
            self.path = path
        }
    }

    public enum Action {
        case userList(UserListFeature.Action)
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
        Scope(state: \.userList, action: \.userList) {
            UserListFeature()
        }
        Reduce { state, action in
            switch action {
            // MARK: Case B — UserList 가 User 객체째로 던지면 detail push
            case let .userList(.delegate(.userTappedRow(user))):
                state.path.append(.detail(UserDetailFeature.State(user: user)))
                return .none

            // MARK: Case A — UserDetail 이 id 만 던지면 profile push
            case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
                state.path.append(.profile(ProfileFeature.State(profileId: id)))
                return .none

            // MARK: Case C — Profile 저장 결과를 받아 목록·상세 갱신 + pop
            case let .path(.element(id: _, action: .profile(.delegate(.profileSaved(profile))))):
                applyProfileUpdate(profile, to: &state)
                if !state.path.isEmpty {
                    state.path.removeLast()
                }
                return .none

            case .userList, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    /// Case C 의 본체. 저장된 `Profile` 을 목록과 스택의 상세 양쪽에 반영.
    private func applyProfileUpdate(_ profile: Profile, to state: inout State) {
        if let index = state.userList.users.firstIndex(where: { $0.id == profile.id }) {
            state.userList.users[index].name = profile.displayName
            state.userList.users[index].bio = profile.bio
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

extension AppFeature.Path.State: Equatable {}
