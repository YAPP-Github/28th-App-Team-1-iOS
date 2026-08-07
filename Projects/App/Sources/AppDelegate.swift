//
//  AppDelegate.swift
//  Hilit
//
//  Created by 서정원 on 26/08/06.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import UIKit

/// background URLSession wake 수신 전용 어댑터 — 영상 PUT 이 앱 종료 후 끝나면 iOS 가 앱을 백그라운드로
/// 재기동해 이 콜백만 부른다(SwiftUI Scene 은 안 뜬다). completionHandler 를 전송 계층에 맡겨
/// 이벤트 소진 시점에 호출되게 하고, 큐 재개로 후속(complete 확정)을 잇되 그 후속은 background task
/// assertion 으로 붙잡는다(스펙 ④·⑤).
final class AppDelegate: NSObject, UIApplicationDelegate {
    @Dependency(\.backgroundTransferClient) var backgroundTransfer
    @Dependency(\.interviewVideoUploadQueue) var uploadQueue

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == BackgroundTransferClient.sessionIdentifier else { return completionHandler() }
        let handler = UncheckedSendable(completionHandler)
        backgroundTransfer.attachBackgroundEventsCompletionHandler { handler.value() }
        // completionHandler 는 *URLSession 이벤트*가 소진되면 불리는데, 큐의 후속(`completeVideoUpload`)은
        // 그 뒤에도 남는다 — 그대로 두면 iOS 가 곧장 앱을 정지시켜 complete 가 잘리고 저널만 `.completing`
        // 으로 남는다(데이터는 안전하지만 그 사이 서버가 영상 없이 리포트를 확정할 수 있다).
        // assertion 으로 재개가 잦아들 때까지(= `resumePending()` 반환) 정지를 미룬다.
        // `assertion` 은 락 없이 안전하다 — 이 델리게이트 메서드는 @MainActor(UIApplicationDelegate 주석)라
        // Task 도 메인 격리를 상속하고, 만료 핸들러 역시 항상 메인 스레드에서 불린다(UIKit 문서).
        // 접근 3곳(할당·본문 end·만료 end)이 전부 메인 직렬이라 guard+invalid 리셋만으로 1회 반납이 성립한다.
        Task {
            var assertion: UIBackgroundTaskIdentifier = .invalid
            let end = {
                guard assertion != .invalid else { return }
                application.endBackgroundTask(assertion)
                assertion = .invalid   // 이중 반납은 크래시 — 만료·정상 종료 어느 쪽이 먼저 와도 1회만
            }
            assertion = application.beginBackgroundTask(withName: "InterviewVideoUploadResume", expirationHandler: end)
            await uploadQueue.resumePending()
            end()
        }
    }
}
