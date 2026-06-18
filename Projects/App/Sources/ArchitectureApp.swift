//
//  ArchitectureApp.swift
//  Architecture
//
//  Created by EunseoKim on 5/19/26.
//

import AppConfig
import AppFeature
import ComposableArchitecture
import SwiftUI

@main
struct ArchitectureApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        @Dependency(\.appConfig) var config
        print("🚀 환경=\(config.environment.rawValue) baseURL=\(config.baseURL.absoluteString)")
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
