//
//  InterviewClientLive.swift
//  DomainInterviewImplementation
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import Foundation

// @lat: [[interview#API]]
// depends-on: [[domain.map#네트워킹 인프라]] (AuthorizedNetworkClient — Bearer 첨부·자동 재발급은 인프라가 처리)
extension InterviewClient: @retroactive DependencyKey {
    public static var liveValue: InterviewClient {
        @Dependency(\.authorizedNetworkClient) var network

        return InterviewClient(
            createSession: { config in
                let request = try NetworkRequest.json(
                    method: .post,
                    path: "/api/v1/interview/sessions",
                    body: SessionCreateBody(config),
                    encoder: .api
                )
                return try await network.api(request)
            },
            sessionStatus: { sessionId in
                try await network.api(NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/status"))
            },
            submitAnswer: { sessionId, submission in
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
            },
            questionAudioStream: { sessionId, questionId in
                let path = "/api/v1/interview/sessions/\(sessionId)/questions/\(questionId)/audio/stream"
                let resource = try await network.authorizedResource(path)
                return InterviewAudioStream(url: resource.url, headers: resource.headers)
            }
        )
    }
}

// MARK: - 서버 계약 매핑

/// jdUrl/jdText 상호 배타 규칙을 enum(JobDescriptionInput)에서 서버 필드로 펼친다.
private struct SessionCreateBody: Encodable {
    let portfolioId: UUID
    let jobRole: String
    let careerYears: Int
    let jdUrl: String?
    let jdText: String?
    let freeText: String?

    init(_ config: InterviewConfig) {
        portfolioId = config.portfolioId
        jobRole = config.jobRole
        careerYears = config.careerYears
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
        if let isWrapUp {
            items.append(.init(name: "isWrapUp", value: isWrapUp ? "true" : "false"))
        }
        return items
    }
}
