//
//  FeatureMyPageExampleApp.swift
//  FeatureMyPageExample
//
//  Created by 서정원 on 26/08/01.
//

import ComposableArchitecture
import FeatureMyPageImplementation
import SwiftUI

// Feature 단독 실행 앱 — FeatureMyPage 스킴의 실행 타겟.
// 이 Feature 만 격리해 띄워보는 용도 — 외부 IO 는 가짜(preview/test) 의존성으로 주입해 네트워크 없이 돌린다.
@main
struct FeatureMyPageExampleApp: App {
    var body: some Scene {
        WindowGroup {
            MyPageView(
                store: Store(initialState: MyPageFeature.State()) {
                    MyPageFeature()
                }
            )
        }
    }
}

// MARK: - 작성 가이드
//
// ▸ 특정 상태로 시작:
//     Store(initialState: MyPageFeature.State(items: [.mock])) { MyPageFeature() }
//
// ▸ 가짜 의존성 주입 (외부 IO 가 있는 Feature):
//     Store(initialState: MyPageFeature.State()) {
//         MyPageFeature()
//     } withDependencies: {
//         $0.someClient = .preview          // .testValue(unimplemented) 대신 preview 스텁으로 화면 확인
//     }
