//
//  JobClient.swift
//  DomainJobInterface
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 선택 가능한 직무. `jobRole` 이 서버 Enum 값 — `InterviewConfig.jobRole` 로 그대로 전달한다.
public struct Job: Decodable, Equatable, Sendable, Identifiable {
    public let jobId: Int
    /// 서버 Enum 값 (예: "BACKEND")
    public let jobRole: String
    /// 한글 표시명 (예: "백엔드")
    public let label: String

    public var id: Int { jobId }

    public init(jobId: Int, jobRole: String, label: String) {
        self.jobId = jobId
        self.jobRole = jobRole
        self.label = label
    }
}

public extension Job {
    /// Preview(`previewValue`)·mock 공용 샘플.
    static let previews: [Job] = [
        Job(jobId: 1, jobRole: "BACKEND", label: "백엔드"),
        Job(jobId: 2, jobRole: "FRONTEND", label: "프론트엔드"),
        Job(jobId: 3, jobRole: "IOS", label: "iOS")
    ]
}

// MARK: - Client

/// 직무 API (D14 `/api/v1/jobs`) — Setup 위저드 직군 선택지.
// @lat: [[api#Job]]
public struct JobClient: Sendable {
    /// GET /jobs — 선택 가능한 직무 목록.
    public var jobs: @Sendable () async throws -> [Job]

    public init(jobs: @escaping @Sendable () async throws -> [Job]) {
        self.jobs = jobs
    }
}

extension JobClient: TestDependencyKey {
    public static var testValue: JobClient {
        JobClient(jobs: unimplemented("JobClient.jobs", placeholder: []))
    }

    public static var previewValue: JobClient {
        JobClient(jobs: { Job.previews })
    }
}

public extension DependencyValues {
    var jobClient: JobClient {
        get { self[JobClient.self] }
        set { self[JobClient.self] = newValue }
    }
}
