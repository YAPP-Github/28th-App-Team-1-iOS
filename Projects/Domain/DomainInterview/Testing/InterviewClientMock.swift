//
//  InterviewClientMock.swift
//  DomainInterviewTesting
//
//  Created by EunseoKim on 26/07/07.
//

import DomainInterviewInterface
import Foundation

public extension InterviewClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 샘플을 그대로 돌려준다.
    static var mock: InterviewClient {
        InterviewClient(fetchInterviews: { Interview.previews })
    }
}
