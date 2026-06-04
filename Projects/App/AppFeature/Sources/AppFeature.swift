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
import Models
import ProfileFeature
import UsersFeature

/// 앱 최상위 Reducer 겸 탭 코디네이터.
///
/// 4개 탭(Home / Users / Activity / Profile)의 State 를 보유하고,
/// **Feature 간(cross-feature) 전환은 여기서만** 조립한다.
/// 각 Feature 는 서로를 알지 못하고 delegate 로만 의사를 전달한다.
@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab
        public var home: HomeFeature.State
        public var users: UsersFeature.State
        public var activity: ActivityFeature.State
        public var profile: ProfileFeature.State
        /// Users 흐름에서 올라온 "프로필 편집" 요청을 앱 레벨에서 제시.
        @Presents public var editProfile: ProfileFeature.State?

        public init(
            selectedTab: Tab = .home,
            home: HomeFeature.State = .init(),
            users: UsersFeature.State = .init(),
            activity: ActivityFeature.State = .init(),
            profile: ProfileFeature.State = .init(profileId: 1),
            editProfile: ProfileFeature.State? = nil
        ) {
            self.selectedTab = selectedTab
            self.home = home
            self.users = users
            self.activity = activity
            self.profile = profile
            self.editProfile = editProfile
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
        case users(UsersFeature.Action)
        case activity(ActivityFeature.Action)
        case profile(ProfileFeature.Action)
        case editProfile(PresentationAction<ProfileFeature.Action>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.users, action: \.users) {
            UsersFeature()
        }
        Scope(state: \.activity, action: \.activity) {
            ActivityFeature()
        }
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }
        Reduce { state, action in
            switch action {
            // Users 상세 → 프로필 편집 요청: 앱 레벨 sheet 로 제시.
            case let .users(.delegate(.editProfile(id))):
                state.editProfile = ProfileFeature.State(profileId: id)
                return .none

            // 편집 저장 완료: sheet 닫고, 결과를 Users 도메인에 통보.
            case let .editProfile(.presented(.delegate(.profileSaved(profile)))):
                state.editProfile = nil
                return .send(.users(.profileUpdated(profile)))

            case .binding, .home, .users, .activity, .profile, .editProfile:
                return .none
            }
        }
        .ifLet(\.$editProfile, action: \.editProfile) {
            ProfileFeature()
        }
    }
}
