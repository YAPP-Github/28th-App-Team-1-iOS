//
//  HomeExampleApp.swift
//  HomeFeatureExample
//
//  HomeFeature 만 단독 실행하는 예제 앱.
//

import ComposableArchitecture
import HomeFeature
import SwiftUI

@main
struct HomeExampleApp: App {
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
