//
//  JDClientMock.swift
//  DomainJDTesting
//
//  Created by EunseoKim on 26/07/18.
//

import DomainJDInterface
import Foundation

public extension JDClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 검증 성공을 그대로 돌려준다.
    static var mock: JDClient {
        JDClient(validate: { _ in JDValidation(valid: true, reason: nil, message: nil) })
    }
}
