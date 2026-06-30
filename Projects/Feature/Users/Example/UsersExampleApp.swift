//
//  UsersExampleApp.swift
//  UsersFeatureExample
//
//  UsersFeature 만 단독 실행하는 예제 앱.
//  UserClientLive 를 link 하므로 실제(mock-delay) 데이터로 구동된다.
//

import ComposableArchitecture
import SwiftUI
import DomainUserLive
import FeatureUsers

@main
struct UsersExampleApp: App {
    var body: some Scene {
        WindowGroup {
            UsersView(
                store: Store(initialState: UsersFeature.State()) {
                    UsersFeature()
                }
            )
        }
    }
}
