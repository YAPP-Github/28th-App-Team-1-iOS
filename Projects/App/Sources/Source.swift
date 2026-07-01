import Core
import Domain
import Feature
import Shared

import SwiftUI
import ComposableArchitecture

@main
struct YappApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) {
                AppFeature()
            })
        }
    }
}
