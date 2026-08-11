//
//  ServerEnvelope.swift
//  CoreNetworkInterface
//
//  Created by EunseoKim on 26/07/18.
//

import CoreCommonInterface
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
            if LogGate.isVerbose {
                NetworkDecodeLogger.failure(type: T.self, body: data, envelopeError: envelopeError, fallbackError: error)
            }
            throw envelopeError
        }
    }
}

/// 디코딩 실패 로깅 — HTTP 는 200 인데 계약이 어긋난 경우를 눈에 보이게 한다.
/// 이게 없으면 도메인 에러 매핑이 `unexpected` 로 뭉개 «왜 실패했는지» 가 사라진다.
/// 노출 여부는 런타임 `LogGate.isVerbose`.
enum NetworkDecodeLogger {
    static func failure(type: Any.Type, body: Data, envelopeError: any Error, fallbackError: any Error) {
        print("🧩 [DECODE-FAIL] \(type)")
        print("   envelope: \(envelopeError)")
        print("   직접디코드: \(fallbackError)")
        if !body.isEmpty {
            // 계약이 어긋난 응답이라 무엇이 왔는지 원문으로 봐야 한다.
            print("   body: \(String(decoding: body, as: UTF8.self))")
        }
    }
}

/// 서버 에러. 두 포맷이 실재한다(2026-08-02 확인):
/// - **정의된 코드** `{ success: false, code, message }` — `message` 는 그대로 사용자 노출 가능한 한국어 문구,
///   `code` 로 Domain 이 도메인 에러로 매핑한다.
/// - **미정의(Spring 기본)** `{ timestamp, status, error, path }` — 서버가 코드로 승격하지 않은 에러.
///   `code` 는 빈 문자열, `message` 에 `error`("Forbidden" 등)가 들어온다.
public struct ServerError: Error, Equatable, Sendable {
    /// 서버 에러 코드 (예: `PORTFOLIO_ALREADY_EXISTS`, `NO_REMAINING_TICKET`). Spring 기본 포맷이면 빈 문자열.
    public let code: String
    public let message: String
    public let statusCode: Int
    
    public init(code: String, message: String, statusCode: Int) {
        self.code = code
        self.message = message
        self.statusCode = statusCode
    }
    
    /// 비 2xx body(`NetworkError.statusCode` 의 payload)에서 서버 에러를 읽는다.
    /// 정의된 코드 포맷 우선, 아니면 Spring 기본 포맷 — 둘 다 아니면 nil (HTML·평문 등).
    public static func decode(statusCode: Int, body: Data) -> ServerError? {
        struct Failure: Decodable {
            let code: String?
            let message: String?
        }
        if let failure = try? JSONDecoder().decode(Failure.self, from: body), let code = failure.code {
            return ServerError(code: code, message: failure.message ?? "알 수 없는 오류가 발생했어요.", statusCode: statusCode)
        }
        
        struct SpringFailure: Decodable {
            let status: Int?
            let error: String?
        }
        if let failure = try? JSONDecoder().decode(SpringFailure.self, from: body), let error = failure.error {
            return ServerError(code: "", message: error, statusCode: failure.status ?? statusCode)
        }
        return nil
    }
}

public extension ServerError {
    /// 도메인이 승격하지 않은 에러의 **임시 노출 규칙**(2026-08-02 합의) — OS 기본 Alert 에 그대로 싣는다.
    /// 정의된 코드는 «CODE(status)», Spring 기본 포맷은 상태코드만. 도메인별 핸들링이 확정되면 그쪽이 우선.
    var alertTitle: String {
        code.isEmpty ? "\(statusCode)" : "\(code)(\(statusCode))"
    }
    /// Alert 본문 — 정의된 코드는 서버 한국어 문구, Spring 포맷은 `error` 원문("Forbidden" 등).
    var alertMessage: String { message }
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

        // Spring LocalDateTime (타임존 표기 없음) — KST 가정.
        // 소수부 자릿수는 서버가 고정하지 않는다(밀리초~마이크로초, 0 이면 생략) — 잘라내고 초 단위로 되더한다.
        let localDateTime = DateFormatter()
        localDateTime.locale = Locale(identifier: "en_US_POSIX")
        localDateTime.timeZone = TimeZone(identifier: "Asia/Seoul")
        localDateTime.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard let date = localDateTime.date(from: String(parts[0])) else { return nil }
        guard parts.count == 2, let fraction = Double("0.\(parts[1])") else { return date }
        return date.addingTimeInterval(fraction)
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
