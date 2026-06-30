import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        // TODO: 탭바 or 루트 네비게이션 — Feature 모듈 추가 시 여기서 조립
        Text("App")
            .onAppear { store.send(.onAppear) }
    }
}
