//
//  PushNotification.swift
//  CorePushInterface
//
//  Created by EunseoKim on 26/07/20.
//

import Foundation

/// 수신한 푸시 1건의 정제 표현. UN/FCM 원본 타입 대신 이 값만 모듈 경계를 넘는다.
public struct PushNotification: Equatable, Sendable {
    /// 알림 제목 — 없으면 nil (데이터 전용 메시지 등).
    public let title: String?
    /// 알림 본문 — 없으면 nil.
    public let body: String?
    /// userInfo 의 커스텀 key-value (String 값만). 알림 탭 딥링크 분기의 입력이 된다.
    public let data: [String: String]

    public init(title: String?, body: String?, data: [String: String]) {
        self.title = title
        self.body = body
        self.data = data
    }
}

public extension PushNotification {
    /// APNs userInfo 에서 커스텀 데이터만 추린다 — `aps` 시스템 서브트리는 제외하고
    /// String 키·String 값 쌍만 남긴다(FCM data payload 는 전부 String 으로 도착한다).
    static func sanitizedData(from userInfo: [AnyHashable: Any]) -> [String: String] {
        userInfo.reduce(into: [:]) { result, element in
            guard let key = element.key as? String, key != "aps",
                  let value = element.value as? String else { return }
            result[key] = value
        }
    }
}

/// 앱이 반응해야 하는 푸시 이벤트. 발원지(delegate 콜백)와 무관하게 이 두 형태로 정규화된다.
public enum PushEvent: Equatable, Sendable {
    /// 앱 사용 중(포그라운드) 수신 — 시스템 배너는 이미 표시됐고, 인앱 부가 반응용 신호.
    case foregroundReceived(PushNotification)
    /// 알림 탭으로 진입(백그라운드/종료 상태 포함) — 라우팅 트리거.
    case tapped(PushNotification)
}
