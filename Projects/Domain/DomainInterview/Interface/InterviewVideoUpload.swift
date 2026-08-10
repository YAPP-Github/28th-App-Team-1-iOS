//
//  InterviewVideoUpload.swift
//  DomainInterviewInterface
//
//  Created by 서정원 on 26/08/04.
//

import Foundation

/// POST …/video/upload-url 응답 — S3 presigned PUT 대상.
/// PUT 시 `Content-Type` 헤더를 `contentType` 값과 동일하게 보내야 한다 (서명에 포함 — 다르면 S3 가 거부).
public struct InterviewVideoUploadTarget: Decodable, Equatable, Sendable {
    public let uploadUrl: String
    public let contentType: String
    /// 발급 URL 유효 시간(초, 예시 600) — 만료 시 재발급. 저장 위치는 세션당 하나로 고정(재발급 후 재업로드 = 덮어쓰기).
    public let expiresInSeconds: Int

    public init(uploadUrl: String, contentType: String, expiresInSeconds: Int) {
        self.uploadUrl = uploadUrl
        self.contentType = contentType
        self.expiresInSeconds = expiresInSeconds
    }
}

/// POST …/video/complete 선택 바디 — 면접관 마무리 멘트 재생 구간(녹화 타임라인 기준 초).
/// 보내면 합성 영상에 마무리 멘트가 얹히고 리포트 대본에도 포함된다.
public struct InterviewVideoWrapUpSpan: Encodable, Equatable, Sendable {
    public let wrapUpStartSec: Double
    public let wrapUpEndSec: Double

    public init(wrapUpStartSec: Double, wrapUpEndSec: Double) {
        self.wrapUpStartSec = wrapUpStartSec
        self.wrapUpEndSec = wrapUpEndSec
    }
}
