//
//  FeatureInterviewExampleApp.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import FeatureInterviewImplementation
import SwiftUI

// Feature 단독 실행 앱 — FeatureInterview 스킴의 실행 타겟.
// 이 Feature 만 격리해 띄워보는 용도 — 외부 IO 는 가짜(preview/test) 의존성으로 주입해 네트워크 없이 돌린다.
// 카메라·마이크 권한만 예외로 liveValue(DomainPermissionImplementation link) — 준비 화면의
// 사용 시점 요청 → 거부 alert → 설정 이동 흐름을 실기기/시뮬레이터에서 그대로 검증하기 위해서다.
@main
struct FeatureInterviewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            InterviewView(
                store: Store(initialState: InterviewFeature.State()) {
                    InterviewFeature()
                }
            )
        }
    }
}

// MARK: - 작성 가이드
//
// ▸ 특정 상태로 시작:
//     Store(initialState: InterviewFeature.State(items: [.mock])) { InterviewFeature() }
//
// ▸ 가짜 의존성 주입 (외부 IO 가 있는 Feature):
//     Store(initialState: InterviewFeature.State()) {
//         InterviewFeature()
//     } withDependencies: {
//         $0.someClient = .preview          // .testValue(unimplemented) 대신 preview 스텁으로 화면 확인
//     }
