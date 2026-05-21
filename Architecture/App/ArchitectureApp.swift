import ComposableArchitecture
import SwiftUI

@main
struct ArchitectureApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}

/// 앱 최상위 SwiftUI 컨테이너. ``AppFeature`` 의 path 를 `NavigationStack` 에 바인딩한다.
///
/// 새 화면을 추가했다면 아래 `destination` switch 에 case 한 줄을 더하면 끝이다.
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
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
