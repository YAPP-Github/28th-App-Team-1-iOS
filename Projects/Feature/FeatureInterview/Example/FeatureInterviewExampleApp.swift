//
//  FeatureInterviewExampleApp.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/07/25.
//

import AVFoundation
import ComposableArchitecture
import FeatureInterviewImplementation
import SwiftUI

// Feature 단독 실행 앱 — FeatureInterview 스킴의 실행 타겟.
// 이 Feature 만 격리해 띄워보는 용도 — 외부 IO 는 가짜(preview/test) 의존성으로 주입해 네트워크 없이 돌린다.
@main
struct FeatureInterviewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            InterviewView(
                store: Store(initialState: InterviewFeature.State()) {
                    InterviewFeature()
                }
            )
            .task {
                // Example 전용 임시 배선 — PermissionClient(ai-interview.md §6 P0) 도입 전까지
                // 실행 직후 카메라·마이크 권한을 요청해 프리뷰·녹음 확인이 가능하게 한다.
                _ = await AVCaptureDevice.requestAccess(for: .video)
                _ = await AVCaptureDevice.requestAccess(for: .audio)
            }
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
