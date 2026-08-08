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
            // 세션 생성·상태 폴링은 전역 로딩에서 뺀다 — 이 둘을 기다리는 화면이 곧 온보딩
            // 프리로드(체크리스트 3행 + 진행 스피너)라, 그게 대기 표시 그 자체다. 모달을 덮으면
            // 브랜드 대기 화면만 가린다 (AppView 가 Splash 를 제외하는 것과 같은 이유).
            createSession: { config in
                try await GlobalLoadingSuppression.run {
                    try await InterviewError.mapping {
                        let request = try NetworkRequest.json(
                            method: .post,
                            path: "/api/v1/interview/sessions",
                            body: SessionCreateBody(config),
                            encoder: .api
                        )
                        return try await network.api(request)
                    }
                }
            },
            sessionStatus: { sessionId in
                try await GlobalLoadingSuppression.run {
                    try await InterviewError.mapping {
                        try await network.api(
                            NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/status")
                        )
                    }
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
            checkResume: { sessionId in
                try await InterviewError.mapping {
                    try await network.api(
                        NetworkRequest(path: "/api/v1/interview/sessions/\(sessionId)/resume")
                    )
                }
            },
            // 재개 확정은 body 가 없다 — 같은 경로의 POST 하나로 서버가 이용권 hold 를 재확인하고 턴을 돌려준다.
            confirmResume: { sessionId in
                try await InterviewError.mapping {
                    try await network.api(
                        NetworkRequest(method: .post, path: "/api/v1/interview/sessions/\(sessionId)/resume")
                    )
                }
            },
            abandonSession: { sessionId, cause in
                try await InterviewError.mapping {
                    let request = try NetworkRequest.json(
                        method: .post,
                        path: "/api/v1/interview/sessions/\(sessionId)/abandon",
                        body: AbandonBody(cause),
                        encoder: .api
                    )
                    return try await network.api(request)
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

/// POST .../abandon 요청 body — 사유 하나뿐이다. 요청 enum 에 `HOLD_EXPIRED` 가 없어
/// `INVALID_ABANDON_CAUSE`(400) 는 타입 단계에서 막힌다.
private struct AbandonBody: Encodable {
    let cause: String

    init(_ cause: AbandonCause) {
        self.cause = cause.rawValue
    }
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
