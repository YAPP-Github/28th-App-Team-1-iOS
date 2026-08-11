//
//  JobClientMock.swift
//  DomainJobTesting
//
//  Created by EunseoKim on 26/07/18.
//

import DomainJobInterface
import Foundation

public extension JobClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 샘플을 그대로 돌려준다.
    static var mock: JobClient {
        JobClient(jobs: { Job.previews })
    }
}
