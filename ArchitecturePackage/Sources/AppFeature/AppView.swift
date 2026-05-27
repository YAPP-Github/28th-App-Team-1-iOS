//
//  AppView.swift
//  AppFeature
//
//  Created by EunseoKim on 5/26/26.
//

import ActivityFeature
import ComposableArchitecture
import HomeFeature
import ProfileFeature
import SwiftUI
import UserFeature

/// 앱 최상위 SwiftUI 컨테이너. ``AppFeature`` 의 4 탭 라우팅.
public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.selectedTab) {
            HomeView(
                store: store.scope(state: \.home, action: \.home)
            )
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppFeature.Tab.home)

            UserFeatureView(
                store: store.scope(state: \.users, action: \.users)
            )
            .tabItem { Label("Users", systemImage: "person.2") }
            .tag(AppFeature.Tab.users)

            ActivityView(
                store: store.scope(state: \.activity, action: \.activity)
            )
            .tabItem { Label("Activity", systemImage: "bell") }
            .tag(AppFeature.Tab.activity)

            NavigationStack {
                ProfileView(
                    store: store.scope(state: \.profile, action: \.profile)
                )
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(AppFeature.Tab.profile)
        }
    }
}
