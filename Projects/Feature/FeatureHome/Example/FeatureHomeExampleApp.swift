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
            // 실전(AppView)과 같은 조건 — 로고 내비바는 시스템 바 기반이라 스택 밖에선 안 그려진다.
            NavigationStack {
                HomeView(
                    store: Store(initialState: HomeFeature.State()) {
                        HomeFeature()
                    }
                )
            }
        }
    }
}
