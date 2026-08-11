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
/// 실행 인자로 켜는 우회로는 두지 않는다 — 운영 구성에서 로그를 열 수 있는 경로 자체를 남기지 않는다.
/// 로컬에서 봐야 하면 Dev/QA 스킴으로 실행한다.
///
/// - Important: 켜져도 자격증명은 `LogRedaction` 이 가린다. 로거를 새로 만들 땐 그걸 반드시 통과시킨다.
// @lat: [[api#서버와 환경]]
public enum LogGate {
    /// 상세 로그를 켜는 계 — 이 목록에 없는 값(누락·오타·새 계)은 전부 끈다.
    private static let verboseEnvironments: Set<String> = ["dev", "qa"]

    /// 상세 로그를 찍을 것인가. 계 판정은 프로세스 수명 동안 바뀌지 않으므로 한 번만 계산한다.
    public static let isVerbose: Bool = {
        #if DEBUG
        // Example 하네스처럼 APP_ENV 를 심지 않는 타겟도 있어 DEBUG 은 계와 무관하게 켠다.
        return true
        #else
        guard let environment = Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String else {
            return false
        }
        return verboseEnvironments.contains(environment)
        #endif
    }()
}
