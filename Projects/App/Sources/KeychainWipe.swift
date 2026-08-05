//
//  KeychainWipe.swift
//  Hilit
//
//  Created by EunSeo on 26/08/03.
//

import Foundation
import Security

/// 앱이 Keychain 에 남긴 항목을 **클래스 단위로 전부** 지운다.
///
/// `TokenStore.clear()` 를 쓰지 않는 이유: 그건 `account: "auth-tokens"` 한 항목만 지운다.
/// 첫 실행 정리·로그아웃이 노리는 건 «앱이 남긴 것 전부» 라, 항목이 늘어도 안 놓치려면
/// 클래스 단위로 지워야 한다. 프로덕션 계약(`TokenStore`)에 전체 삭제를 만들지 않은 것도
/// 같은 이유 — 토큰 스토어의 책임은 자기 항목이고, 전체 폐기는 composition root 의 판단이다.
///
/// 앱 샌드박스 밖은 건드리지 않는다: 쿼리에 서비스 제한을 걸지 않아도 앱은 자기
/// keychain-access-group 안의 항목만 볼 수 있다.
enum KeychainWipe {
    /// 아이템 클래스 5종을 각각 비운다 — 한 쿼리로 여러 클래스를 지울 수 없다.
    /// 실패는 무시한다(정리 도구라 부분 실패도 멈추는 것보다 낫다). `errSecItemNotFound` 는 «비어 있음».
    static func wipeAll() {
        let classes = [
            kSecClassCertificate,
            kSecClassGenericPassword,
            kSecClassIdentity,
            kSecClassInternetPassword,
            kSecClassKey
        ]
        for itemClass in classes {
            SecItemDelete([kSecClass as String: itemClass] as CFDictionary)
        }
    }
}
