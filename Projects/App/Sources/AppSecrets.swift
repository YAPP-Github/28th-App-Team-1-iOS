//
//  AppSecrets.swift
//  App
//
//  Created by 서정원 on 26/07/10.
//

import Foundation

/// Info.plist(xcconfig 치환)에서 시크릿을 읽는 단일 seam.
/// `authClient.configure` 호출부는 이 타입만 참조한다.
enum AppSecrets {
    /// 유니버설 링크(ChottuLink) API 키. **없으면 빈 문자열** — 카카오 키와 달리 assert 하지 않는다.
    /// 키가 비면 잃는 건 deferred 진입(재설치 후 첫 실행)과 클릭 통계뿐이고, 설치 상태의 링크 진입은
    /// Associated Domains 로 OS 가 직접 처리해 그대로 산다. 팀원 로컬 빌드를 이것 때문에 멈추지 않는다.
    static var chottuLinkAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "CHOTTULINK_API_KEY") as? String ?? ""
    }

    static var kakaoNativeAppKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String,
            !key.isEmpty
        else {
            assertionFailure("KAKAO_NATIVE_APP_KEY 가 비어있습니다. Projects/App/Config/Secrets.xcconfig 를 확인하세요(docs/getting-started.md 참고).")
            return ""
        }
        return key
    }
}
