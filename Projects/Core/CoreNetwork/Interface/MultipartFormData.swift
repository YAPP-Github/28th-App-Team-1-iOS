//
//  MultipartFormData.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

/// `multipart/form-data` 본문 (포트폴리오 PDF·답변 음성 업로드).
/// `NetworkRequest.multipart(...)` 빌더가 boundary 조립까지 끝낸 요청을 만든다 — 기존 NetworkRequest 계약은 그대로다.
public struct MultipartFormData: Equatable, Sendable {
    public struct Part: Equatable, Sendable {
        /// form field 이름 (예: "file", "audio")
        public var name: String
        public var fileName: String?
        public var mimeType: String?
        public var data: Data

        public init(name: String, fileName: String? = nil, mimeType: String? = nil, data: Data) {
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
            self.data = data
        }
    }

    public var parts: [Part]

    public init(parts: [Part]) {
        self.parts = parts
    }

    public func encoded(boundary: String) -> Data {
        var body = Data()
        for part in parts {
            body.append("--\(boundary)\r\n")
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let fileName = part.fileName {
                disposition += "; filename=\"\(fileName)\""
            }
            body.append("\(disposition)\r\n")
            if let mimeType = part.mimeType {
                body.append("Content-Type: \(mimeType)\r\n")
            }
            body.append("\r\n")
            body.append(part.data)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        return body
    }
}

public extension NetworkRequest {
    /// multipart 요청 빌더 — `Content-Type` boundary 헤더와 body 인코딩까지 세팅한다.
    /// 응답 쪽 `NetworkClient.api(_:as:)` 와 대칭 (요청 편의는 `json(...)` 과 동급).
    static func multipart(
        method: Method = .post,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        form: MultipartFormData
    ) -> NetworkRequest {
        let boundary = "hilit.boundary.\(UUID().uuidString)"
        var headers = headers
        headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        return NetworkRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            headers: headers,
            body: form.encoded(boundary: boundary)
        )
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
