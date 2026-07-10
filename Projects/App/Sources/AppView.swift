import SwiftUI
import ComposableArchitecture
import Feature

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.isAuthenticated {
                TabView(selection: $store.selectedTab) {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                        .tabItem { Label("홈", systemImage: "house") }
                        .tag(AppFeature.Tab.home)
                }
            } else {
                AuthView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
