//
//  LogGate.swift
//  CoreCommonInterface
//

import Foundation

/// 상세 로그(네트워크 요청/응답·디코딩 실패·부팅 라우팅) 노출 게이트.
///
/// 예전엔 `#if DEBUG` 로 잘라 QA/Prod 빌드엔 아예 컴파일되지 않았다 — 그래서 릴리즈 구성으로
/// 도는 QA 에서도 로그를 볼 수 없었다. 이제 컴파일은 항상 하고 **런타임**에 계로 판정한다.
///
/// **판정은 허용 목록(fail closed)이다** — `APP_ENV` 가 `dev`·`qa` 일 때만 켠다. 반대로 «prod 가
/// 아니면 켠다» 로 쓰면 키 누락·오타(`Prod`·`production`)·새 계 이름이 전부 «켜라» 로 읽혀,
/// 실수 한 번이 운영 빌드에서 토큰 유출로 바뀐다. 모르는 값은 끄는 쪽이 안전한 실패다.
///
/// **운영 구성도 디버거가 붙어 있으면 연다** — Prod 로만 재현되는 문제(스토어 빌드 응답·라우팅)를
/// 볼 길이 필요하다. 판정 근거를 «디버거 존재» 로 잡은 이유: 스토어에서 받아 탭해 켠 앱은 어떤 조작으로도
/// 참이 되지 않는다. 실행 인자(`-verboseLog`)나 숨은 설정 토글은 **켜진 채 남을 수 있는 스위치**라 두지
/// 않는다 — 여긴 남을 상태가 없고, 켜는 행위 자체가 이미 기기·바이너리를 쥔 개발자여야 가능하다.
///
/// - Important: 값은 가리지 않는다 — 열리면 헤더·바디 원문이 토큰째로 콘솔에 나간다. 이 게이트가 유일한
///   방어선이므로, 로거를 새로 만들 땐 반드시 이 게이트 안에서만 찍는다.
// @lat: [[api#서버와 환경]]
public enum LogGate {
    /// 상세 로그를 켜는 계 — 이 목록에 없는 값(누락·오타·새 계)은 전부 끈다.
    private static let verboseEnvironments: Set<String> = ["dev", "qa"]

    /// 상세 로그를 찍을 것인가. 계·디버거 판정 모두 프로세스 수명 동안 바뀌지 않으므로 한 번만 계산한다.
    public static let isVerbose: Bool = {
        #if DEBUG
        // Example 하네스처럼 APP_ENV 를 심지 않는 타겟도 있어 DEBUG 은 계와 무관하게 켠다.
        return true
        #else
        if let environment = Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String,
           verboseEnvironments.contains(environment) {
            return true
        }
        // 허용 목록 밖(Prod·키 누락·오타)은 디버거가 붙은 세션에서만 연다.
        return isDebuggerAttached
        #endif
    }()

    /// 이 프로세스에 디버거가 붙어 있는가 — 커널이 들고 있는 `P_TRACED` 플래그를 읽는다.
    ///
    /// Xcode·lldb 로 띄운 세션에서만 참이다. 스토어·TestFlight 에서 받아 탭해 켠 앱은 추적자가 없어
    /// 항상 거짓이고, 앱이 스스로 켤 수 있는 값도 아니다(플래그 소유자는 커널이다).
    /// 판정은 실행 중 바뀔 수 있지만(중간 attach) 로그 게이트는 부팅 시점 한 번으로 충분하다.
    private static var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return info.kp_proc.p_flag & P_TRACED != 0
    }
}
