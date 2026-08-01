//
//  ConsentClientMock.swift
//  DomainConsentTesting
//
//  Created by EunseoKim on 26/08/01.
//

import DomainConsentInterface
import Foundation

public extension ConsentClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 동의 최신 상태(항목 없음)와 무해한 성공을 돌려준다.
    static var mock: ConsentClient {
        ConsentClient(
            pending: { ConsentPending(status: .upToDate, items: []) },
            document: { item, version in
                ConsentDocument(item: item, version: version, title: "서비스 이용약관", content: "본문")
            },
            submit: { _ in }
        )
    }
}
