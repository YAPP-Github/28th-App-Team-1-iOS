//
//  InterviewClientLive.swift
//  DomainInterviewImplementation
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainInterviewInterface
import Foundation

// @lat: [[interview#API]]
// depends-on: [[domain.map#네트워킹 인프라]] (AuthorizedNetworkClient — Bearer 첨부·자동 재발급은 인프라가 처리)
extension InterviewClient: @retroactive DependencyKey {
    public static var liveValue: InterviewClient {
        @Dependency(\.authorizedNetworkClient) var network

        return InterviewClient(
            createSession: { config in
                try await InterviewError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/interview/sessions",
                        body: SessionCreateBody(config),
                        encoder: .api
                    )
                    return try await network.api(request)
                }
            },
            sessionStatus: { sessionId in
                try await InterviewError.mapping {
                    try await network.api(NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/status"))
                }
            },
            submitAnswer: { sessionId, submission in
                try await InterviewError.mapping {
                    var parts: [MultipartFormData.Part] = []
                    if let audio = submission.audio {
                        parts.append(.init(name: "audio", fileName: "answer.mp3", mimeType: "audio/mpeg", data: audio))
                    }
                    let request = NetworkRequest.multipart(
                        path: "/api/v1/interview/sessions/\(sessionId)/answers",
                        queryItems: submission.queryItems,
                        form: MultipartFormData(parts: parts)
                    )
                    return try await network.api(request)
                }
            },
            questionAudioStream: { sessionId, questionId in
                try await InterviewError.mapping {
                    let path = "/api/v1/interview/sessions/\(sessionId)/questions/\(questionId)/audio/stream"
                    let resource = try await network.authorizedResource(path)
                    return InterviewAudioStream(url: resource.url, headers: resource.headers)
                }
            },
            videoUploadURL: { sessionId in
                try await InterviewError.mapping {
                    try await network.api(
                        NetworkRequest(method: .post, path: "/api/v1/interview/sessions/\(sessionId)/video/upload-url")
                    )
                }
            },
            completeVideoUpload: { sessionId, wrapUp in
                try await InterviewError.mapping {
                    let path = "/api/v1/interview/sessions/\(sessionId)/video/complete"
                    // 계약: 마무리 멘트가 없으면 바디 자체를 생략한다 (빈 JSON 아님).
                    let request: NetworkRequest
                    if let wrapUp {
                        request = try .json(method: .post, path: path, body: wrapUp, encoder: .api)
                    } else {
                        request = NetworkRequest(method: .post, path: path)
                    }
                    try await network.api(request)
                }
            },
            reportList: {
                try await InterviewError.mapping {
                    let response: ReportListResponse = try await network.api(
                        NetworkRequest(path: "/api/v1/interview/sessions")
                    )
                    return response.reports
                }
            }
        )
    }
}

// MARK: - 서버 계약 매핑

/// GET /interview/sessions 의 payload — `reports` 배열만 도메인에 흘린다.
private struct ReportListResponse: Decodable {
    let reports: [InterviewReportSummary]
}

/// jdUrl/jdText 상호 배타 규칙을 enum(JobDescriptionInput)에서 서버 필드로 펼친다.
/// 직군·연차는 싣지 않는다 — 서버가 회원 프로필 스냅샷을 쓴다(2026-08-02 스펙).
private struct SessionCreateBody: Encodable {
    let portfolioId: UUID
    let jdUrl: String?
    let jdText: String?
    let freeText: String?

    init(_ config: InterviewConfig) {
        portfolioId = config.portfolioId
        switch config.jobDescription {
        case .url(let url):
            jdUrl = url
            jdText = nil
        case .text(let text):
            jdUrl = nil
            jdText = text
        case nil:
            jdUrl = nil
            jdText = nil
        }
        freeText = config.freeText
    }
}

private extension AnswerSubmission {
    /// 서버 계약: 파일(audio)만 multipart, 나머지 메타데이터는 전부 query.
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [.init(name: "questionId", value: String(questionId))]
        func append(_ name: String, _ value: Double?) {
            if let value {
                items.append(.init(name: name, value: String(value)))
            }
        }
        append("questionAudioStartAt", questionAudioStartAt)
        append("questionAudioEndAt", questionAudioEndAt)
        append("answerStartAt", answerStartAt)
        append("answerEndAt", answerEndAt)
        append("answerDuration", answerDuration)
        if let endType {
            items.append(.init(name: "endType", value: endType.rawValue))
        }
        // isWrapUp 은 스펙 required — 항상 싣는다(nil 경로 없음).
        items.append(.init(name: "isWrapUp", value: isWrapUp ? "true" : "false"))
        return items
    }
}
