//
//  AppView.swift
//  AppFeature
//
//  Created by EunseoKim on 5/26/26.
//

import ComposableArchitecture
import ProfileFeature
import SwiftUI
import UserDetailFeature
import UserListFeature

/// 앱 최상위 SwiftUI 컨테이너. ``AppFeature`` 의 path 를 `NavigationStack` 에 바인딩한다.
public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            UserListView(
                store: store.scope(state: \.userList, action: \.userList)
            )
        } destination: { store in
            switch store.case {
            case let .detail(detailStore):
                UserDetailView(store: detailStore)
            case let .profile(profileStore):
                ProfileView(store: profileStore)
            }
        }
    }
}
