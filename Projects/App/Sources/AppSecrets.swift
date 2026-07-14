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
