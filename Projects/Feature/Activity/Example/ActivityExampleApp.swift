//
//  ActivityExampleApp.swift
//  ActivityFeatureExample
//
//  ActivityFeature 만 단독 실행하는 예제 앱.
//  ActivityClientLive 를 link 하므로 실제(mock-delay) 데이터로 구동된다.
//

import ActivityClientLive
import ActivityFeature
import ComposableArchitecture
import SwiftUI

@main
struct ActivityExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ActivityView(
                store: Store(initialState: ActivityFeature.State()) {
                    ActivityFeature()
                }
            )
        }
    }
}
