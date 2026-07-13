//
//  InterviewClient.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import Foundation

// @lat: [[interview#Client 계약]]
// Feature 가 Interview 도메인에 접근하는 유일한 계약.
// testValue/previewValue 는 여기(Interface), liveValue 는 Implementation — App/Example 만 link (D4).
public struct InterviewClient: Sendable {
    /// 내 면접 세션 목록을 최신순으로 가져온다.
    public var fetchInterviews: @Sendable () async throws -> [Interview]

    public init(fetchInterviews: @escaping @Sendable () async throws -> [Interview]) {
        self.fetchInterviews = fetchInterviews
    }
}

extension InterviewClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: InterviewClient {
        InterviewClient(
            fetchInterviews: unimplemented("InterviewClient.fetchInterviews", placeholder: [])
        )
    }

    /// Preview 용 — 네트워크 없이 샘플로 화면을 그린다.
    public static var previewValue: InterviewClient {
        InterviewClient(fetchInterviews: { Interview.previews })
    }
}

public extension DependencyValues {
    var interviewClient: InterviewClient {
        get { self[InterviewClient.self] }
        set { self[InterviewClient.self] = newValue }
    }
}
