//
//  UserFeatureView.swift
//  UserFeature
//
//  Created by EunseoKim on 5/27/26.
//

import ComposableArchitecture
import ProfileFeature
import SwiftUI

/// User 도메인의 NavigationStack 컨테이너.
///
/// 탭 안에서 List → Detail → Profile 편집까지 한 스택 안에서 흐른다.
public struct UserFeatureView: View {
    @Bindable var store: StoreOf<UserFeature>

    public init(store: StoreOf<UserFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            UserListView(
                store: store.scope(state: \.list, action: \.list)
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
