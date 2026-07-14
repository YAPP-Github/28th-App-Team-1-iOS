//
//  FeatureHomeExampleApp.swift
//  FeatureHomeExample
//
//  Created by 서정원 on 26/07/13.
//

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
