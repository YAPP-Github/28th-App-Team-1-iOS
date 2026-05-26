//
//  ArchitectureApp.swift
//  Architecture
//
//  Created by EunseoKim on 5/19/26.
//

import AppFeature
import ComposableArchitecture
import SwiftUI

@main
struct ArchitectureApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
