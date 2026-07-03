import ComposableArchitecture
import FeatureHomeImplementation
import SwiftUI

@main
struct FeatureHomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(
                store: Store(initialState: HomeFeature.State()) {
                    HomeFeature()
                }
            )
        }
    }
}
