//
//  UsersView.swift
//  UsersFeature
//
//  Created by EunseoKim on 5/27/26.
//

import ComposableArchitecture
import SwiftUI

/// User 도메인의 NavigationStack 컨테이너 — 탭 안에서 List → Detail 로 흐른다.
public struct UsersView: View {
    @Bindable var store: StoreOf<UsersFeature>

    public init(store: StoreOf<UsersFeature>) {
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
            }
        }
    }
}
