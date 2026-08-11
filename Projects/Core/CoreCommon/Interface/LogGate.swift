//
//  LogGate.swift
//  CoreCommonInterface
//

import Foundation

/// 상세 로그(네트워크 요청/응답·디코딩 실패·부팅 라우팅) 노출 게이트.
///
/// 예전엔 `#if DEBUG` 로 잘라 QA/Prod 빌드엔 아예 컴파일되지 않았다 — 그래서 릴리즈 구성으로
/// 도는 QA 에서도 로그를 볼 수 없었다. 이제 컴파일은 항상 하고 **런타임**에 계로 판정한다.
/// 판정 기준은 `APP_ENV`(계별 xcconfig → Info.plist) 로, 운영계(`prod`)만 끈다.
///
/// 운영 빌드에서 잠깐 봐야 하면 실행 인자 `-verboseLog` 를 준다 (Xcode 스킴 → Run → Arguments).
/// 설치본(TestFlight/스토어)은 실행 인자를 못 주므로 운영에선 사실상 항상 꺼진 상태다.
///
/// - Important: 켜지면 요청 헤더(`Authorization` 포함)와 바디 원문이 콘솔에 그대로 찍힌다.
// @lat: [[api#서버와 환경]]
public enum LogGate {
    /// 상세 로그를 찍을 것인가. 계 판정은 프로세스 수명 동안 바뀌지 않으므로 한 번만 계산한다.
    public static let isVerbose: Bool = {
        if ProcessInfo.processInfo.arguments.contains("-verboseLog") { return true }
        return (Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String) != "prod"
    }()
}
