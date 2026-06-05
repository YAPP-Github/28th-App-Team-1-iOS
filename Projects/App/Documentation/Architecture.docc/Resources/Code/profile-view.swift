import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        Form {
            TextField("Display name", text: $store.editedDisplayName)
            TextField("Bio", text: $store.editedBio, axis: .vertical)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { store.send(.userTappedSaveButton) }
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
