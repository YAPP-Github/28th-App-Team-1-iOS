//
//  ProfileExampleApp.swift
//  ProfileFeatureExample
//
//  ProfileFeature 만 단독 실행하는 예제 앱.
//  ProfileClientLive 를 link 하므로 실제(mock-delay) 데이터로 구동된다.
//

import ComposableArchitecture
import ProfileClientLive
import ProfileFeature
import SwiftUI

@main
struct ProfileExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProfileView(
                    store: Store(initialState: ProfileFeature.State(profileId: 1)) {
                        ProfileFeature()
                    }
                )
            }
        }
    }
}
