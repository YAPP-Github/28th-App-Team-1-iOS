//
//  AppFeature.swift
//  AppFeature
//
//  Created by EunseoKim on 5/26/26.
//

import ActivityFeature
import ComposableArchitecture
import Foundation
import HomeFeature
import ProfileFeature
import UserFeature

/// 앱 최상위 Reducer 겸 탭 코디네이터.
///
/// 4개 탭 (Home / Users / Activity / Profile) 각각의 State 를 보유하고,
/// 도메인 내부 navigation 은 각 Feature 가 직접 책임진다.
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab
        public var home: HomeFeature.State
        public var users: UserFeature.State
        public var activity: ActivityFeature.State
        public var profile: ProfileFeature.State

        public init(
            selectedTab: Tab = .home,
            home: HomeFeature.State = .init(),
            users: UserFeature.State = .init(),
            activity: ActivityFeature.State = .init(),
            profile: ProfileFeature.State = .init(profileId: 1)
        ) {
            self.selectedTab = selectedTab
            self.home = home
            self.users = users
            self.activity = activity
            self.profile = profile
        }
    }

    public enum Tab: String, Equatable {
        case home
        case users
        case activity
        case profile
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case home(HomeFeature.Action)
        case users(UserFeature.Action)
        case activity(ActivityFeature.Action)
        case profile(ProfileFeature.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.users, action: \.users) {
            UserFeature()
        }
        Scope(state: \.activity, action: \.activity) {
            ActivityFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }
    }
}
