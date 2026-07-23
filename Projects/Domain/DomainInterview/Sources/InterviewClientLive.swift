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
                try await mappingInterviewError {
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
                try await mappingInterviewError {
                    try await network.api(NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/status"))
                }
            },
            submitAnswer: { sessionId, submission in
                try await mappingInterviewError {
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
                try await mappingInterviewError {
                    let path = "/api/v1/interview/sessions/\(sessionId)/questions/\(questionId)/audio/stream"
                    let resource = try await network.authorizedResource(path)
                    return InterviewAudioStream(url: resource.url, headers: resource.headers)
                }
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

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(InterviewError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingInterviewError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw InterviewError(mapping: error)
    }
}

private extension InterviewError {
    /// 서버 에러 코드 → 고정 케이스. 입력 검증군(서버 문구 노출)은 `validationCodes` 로 분리.
    static let serverCodeMap: [String: InterviewError] = [
        "NO_REMAINING_TICKET": .noRemainingTicket,
        "PORTFOLIO_NOT_FOUND": .portfolioNotFound,
        "PORTFOLIO_PROCESSING": .portfolioProcessing,
        "PORTFOLIO_UPLOAD_FAILED": .portfolioUploadFailed,
        "JD_NOT_VALIDATED": .jdNotValidated,
        "FREETEXT_NOT_RELEVANT": .freeTextNotRelevant,
        "INTERVIEW_SESSION_NOT_FOUND": .sessionNotFound,
        "QUESTION_NOT_FOUND": .questionNotFound,
        "ANSWER_ALREADY_SUBMITTED": .answerAlreadySubmitted,
        "SESSION_ALREADY_ENDED": .sessionAlreadyEnded,
        "LOGIN_EXPIRED": .sessionExpired,
        "TOKEN_EXPIRED": .sessionExpired,
        "INVALID_TOKEN": .sessionExpired
    ]

    static let validationCodes: Set<String> = [
        "VALIDATION_ERROR", "INVALID_JOB_ROLE", "INVALID_CAREER_YEARS",
        "INVALID_JD_LENGTH", "INVALID_FREETEXT_LENGTH", "INVALID_PLAYBACK_RANGE",
        "INVALID_ANSWER_RANGE", "INVALID_END_TYPE", "INVALID_AUDIO_PRESENCE"
    ]

    init(mapping error: any Error) {
        switch error {
        case let error as InterviewError:
            self = error
        case let error as ServerError:
            self.init(serverError: error)
        case is NotAuthenticatedError:
            self = .sessionExpired
        case let error as NetworkError:
            self.init(networkError: error)
        default:
            self = .unexpected
        }
    }

    init(serverError error: ServerError) {
        if let fixed = Self.serverCodeMap[error.code] {
            self = fixed
        } else if Self.validationCodes.contains(error.code) {
            self = .invalid(message: error.message)
        } else {
            self = error.statusCode >= 500 ? .serverUnavailable : .unexpected
        }
    }

    init(networkError error: NetworkError) {
        switch error {
        case .transport:
            self = .networkFailure
        case .statusCode(let status, _) where status >= 500:
            self = .serverUnavailable
        default:
            self = .unexpected
        }
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
