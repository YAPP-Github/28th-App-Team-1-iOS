//
//  ServerEnvelope.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/18.
//

import Foundation

// @lat: [[api#공통 규약]]
// D14 서버 공통 응답 포장 — 성공 `{ success, data }` / 실패 `{ success: false, code, message }`.
// `NetworkClient.api(...)` 가 이 규약을 벗겨 Domain 에는 payload 와 ServerError 만 흐르게 한다.
public struct ServerEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    public let success: Bool?
    public let data: T?
    public let code: String?
    public let message: String?
}

public extension ServerEnvelope {
    /// envelope 우선 언랩, 실패 시 `T` 직접 디코드 폴백 — Swagger 일부가 envelope 없이 표기돼 있어(annotation 누락) 방어한다.
    ///
    /// 둘 다 실패하면 **envelope 쪽 에러를 던진다**. 실제 응답은 거의 항상 envelope 이고 안쪽 `T` 가
    /// 계약과 어긋난 경우라, 폴백 에러(«바깥이 T 모양이 아님»)를 던지면 진짜 원인이 가려진다.
    static func unwrap(_ type: T.Type = T.self, from data: Data, decoder: JSONDecoder = .api) throws -> T {
        let envelopeError: any Error
        do {
            // envelope 이 아닌 body 도 여기서 통과한다 — 필드가 전부 옵셔널이라 전원 nil 로 디코딩되고,
            // `data == nil` 이 되어 아래 직접 디코드로 넘어간다.
            if let payload = try decoder.decode(ServerEnvelope<T>.self, from: data).data {
                return payload
            }
            envelopeError = DecodingError.valueNotFound(T.self, .init(
                codingPath: [], debugDescription: "envelope 에 data 가 없다"
            ))
        } catch {
            envelopeError = error
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            NetworkDecodeLogger.failure(type: T.self, body: data, envelopeError: envelopeError, fallbackError: error)
            #endif
            throw envelopeError
        }
    }
}

#if DEBUG
/// 디코딩 실패 로깅 — HTTP 는 200 인데 계약이 어긋난 경우를 눈에 보이게 한다.
/// 이게 없으면 도메인 에러 매핑이 `unexpected` 로 뭉개 «왜 실패했는지» 가 사라진다.
enum NetworkDecodeLogger {
    static func failure(type: Any.Type, body: Data, envelopeError: any Error, fallbackError: any Error) {
        print("🧩 [DECODE-FAIL] \(type)")
        print("   envelope: \(envelopeError)")
        print("   직접디코드: \(fallbackError)")
        if let json = String(data: body, encoding: .utf8) {
            print("   body: \(json)")
        }
    }
}
#endif

/// 서버가 정의한 에러 (`{ success: false, code, message }`).
/// `message` 는 그대로 사용자 노출 가능한 한국어 문구, `code` 로 Domain 이 도메인 에러로 매핑한다.
public struct ServerError: Error, Equatable, Sendable {
    /// 서버 에러 코드 (예: `PORTFOLIO_ALREADY_EXISTS`, `NO_REMAINING_TICKET`)
    public let code: String
    public let message: String
    public let statusCode: Int

    public init(code: String, message: String, statusCode: Int) {
        self.code = code
        self.message = message
        self.statusCode = statusCode
    }

    /// 비 2xx body(`NetworkError.statusCode` 의 payload)에서 서버 에러를 읽는다. envelope 이 아니면 nil.
    public static func decode(statusCode: Int, body: Data) -> ServerError? {
        struct Failure: Decodable {
            let code: String?
            let message: String?
        }
        guard let failure = try? JSONDecoder().decode(Failure.self, from: body), let code = failure.code else {
            return nil
        }
        return ServerError(code: code, message: failure.message ?? "알 수 없는 오류가 발생했어요.", statusCode: statusCode)
    }
}

public extension NetworkClient {
    /// D14 공통 규약 요청 — 성공 envelope 을 벗겨 `T` 를 돌려주고, 비 2xx 는 `ServerError` 로 승격한다
    /// (envelope 이 아닌 에러 body 는 `NetworkError.statusCode` 그대로).
    func api<T: Decodable & Sendable>(
        _ request: NetworkRequest,
        as type: T.Type = T.self,
        decoder: JSONDecoder = .api
    ) async throws -> T {
        try ServerEnvelope<T>.unwrap(from: try await apiData(request), decoder: decoder)
    }

    /// 응답 본문을 쓰지 않는 D14 요청 (204 등) — 서버 에러 승격만 수행한다.
    func api(_ request: NetworkRequest) async throws {
        _ = try await apiData(request)
    }

    private func apiData(_ request: NetworkRequest) async throws -> Data {
        do {
            return try await self.request(request)
        } catch let error as NetworkError {
            if case .statusCode(let status, let body) = error,
               let serverError = ServerError.decode(statusCode: status, body: body) {
                throw serverError
            }
            throw error
        }
    }
}

// MARK: - D14 JSON 코더

// 날짜: 서버가 ISO8601 과 LocalDateTime("2026-07-06T10:00:04", 타임존 없음)을 혼용한다.
// LocalDateTime 은 서버 리전(ap-northeast-2) 기준 KST 로 가정한다. ⚠️ 백엔드와 타임존 계약 확정 시 재확인.
public extension JSONDecoder {
    /// D14 응답 디코더 — 매 호출 새 인스턴스 (JSONDecoder 는 Sendable 이 아니라 공유하지 않는다)
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = parseAPIDate(raw) {
                return date
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "지원하지 않는 날짜 형식: \(raw)"
            ))
        }
        return decoder
    }

    private static func parseAPIDate(_ raw: String) -> Date? {
        let iso8601WithFraction = ISO8601DateFormatter()
        iso8601WithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601WithFraction.date(from: raw) { return date }

        let iso8601 = ISO8601DateFormatter()
        if let date = iso8601.date(from: raw) { return date }

        // Spring LocalDateTime (타임존 표기 없음) — KST 가정
        let localDateTime = DateFormatter()
        localDateTime.locale = Locale(identifier: "en_US_POSIX")
        localDateTime.timeZone = TimeZone(identifier: "Asia/Seoul")
        localDateTime.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return localDateTime.date(from: raw)
    }
}

public extension JSONEncoder {
    /// D14 요청 인코더
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
