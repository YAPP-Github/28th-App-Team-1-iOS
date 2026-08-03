//
//  FeatureInterviewExampleApp.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainSpeechInterface
import FeatureInterviewImplementation
import Foundation
import SwiftUI

// Feature 단독 실행 앱 — FeatureInterview 스킴의 실행 타겟. 모드 2종:
// • preview(기본) — 외부 IO 는 가짜(preview) 의존성으로 주입해 네트워크 없이 화면 흐름만 돌린다.
//   카메라·마이크 권한만 예외로 liveValue(DomainPermissionImplementation link) — 준비 화면의
//   사용 시점 요청 → 거부 alert → 설정 이동 흐름을 실기기/시뮬레이터에서 그대로 검증하기 위해서다.
// • live — 스킴 Run 환경변수 `HILIT_ACCESS_TOKEN` 존재 시 실서버 하네스(LiveInterviewBootstrap).
//   토큰은 Dev 앱에서 브레이크포인트로 추출 — AuthorizedEngine.perform 의 Bearer 부착 줄에
//   Log Message 액션(«🔑 @tokens.accessToken@», Automatically continue)을 걸면 API 호출마다
//   콘솔에 나온다. 그 한 줄을 통째로 복사 (Bearer 접두 없이 원문만, 커밋되는 코드 0줄).
//   ⚠️ tuist generate 가 스킴을 재생성하면 환경변수가 사라진다 — 재입력 필요.
@main
struct FeatureInterviewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            if let token = ProcessInfo.processInfo.environment["HILIT_ACCESS_TOKEN"], !token.isEmpty {
                LiveInterviewBootstrap(accessToken: token)
            } else {
                InterviewView(
                    store: Store(initialState: InterviewFeature.State(sessionId: 1)) {
                        InterviewFeature()
                    } withDependencies: {
                        // 질문 준비 폴링을 네트워크 없이 즉시 READY 로 — 준비 게이트 UI 는 테스트가 고정.
                        $0.interviewClient = .previewValue
                        // 재생도 즉시 완료 스텁 — live 재생 액터가 preview:// URL 로 실패해
                        // 네트워크 실패 화면으로 빠지는 것을 막는다(턴 루프가 즉답으로 순환).
                        $0.speechClient = .previewValue
                    }
                )
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
//     Store(initialState: InterviewFeature.State(sessionId: 1)) {
//         InterviewFeature()
//     } withDependencies: {
//         $0.someClient = .preview          // .testValue(unimplemented) 대신 preview 스텁으로 화면 확인
//     }
