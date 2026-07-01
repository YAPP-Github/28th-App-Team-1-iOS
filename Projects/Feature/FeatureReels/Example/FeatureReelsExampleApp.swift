//
//  FeatureReelsExampleApp.swift
//  FeatureReelsExample
//
//  Created by EunSeo on 26/07/02.
//

import ComposableArchitecture
import FeatureReelsImplementation
import SwiftUI

// FeatureReels 단독 실행 앱 (스킴: FeatureReelsExample).
// Example/Resources 에 reel_sample.mp4 가 있으면 실제 재생, 없으면 poster 폴백으로 인터랙션만 확인한다.
@main
struct FeatureReelsExampleApp: App {
    private var sampleVideoURL: URL? {
        Bundle.main.url(forResource: "reel_sample", withExtension: "mp4")
    }

    var body: some Scene {
        WindowGroup {
            ReelsView(
                store: Store(initialState: .sample(videoURL: sampleVideoURL)) {
                    ReelsFeature()
                }
            )
        }
    }
}
