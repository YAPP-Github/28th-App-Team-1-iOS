//
//  PortfolioClientLive.swift
//  DomainPortfolioImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainPortfolioInterface
import Foundation

// @lat: [[api#Portfolio]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension PortfolioClient: @retroactive DependencyKey {
    public static var liveValue: PortfolioClient {
        @Dependency(\.authorizedNetworkClient) var network

        return PortfolioClient(
            list: {
                try await mappingPortfolioError {
                    let payload: PortfolioListPayload = try await network.api(NetworkRequest(path: "/api/v1/portfolios"))
                    return payload.portfolios
                }
            },
            register: { upload in
                try await mappingPortfolioError {
                    // 서버 계약: 파일 메타데이터는 query, PDF 바이너리만 multipart `file` 파트
                    var query: [URLQueryItem] = [
                        .init(name: "fileName", value: upload.fileName),
                        .init(name: "contentType", value: upload.contentType)
                    ]
                    if let fileSize = upload.fileSize {
                        query.append(.init(name: "fileSize", value: String(fileSize)))
                    }
                    if let pageCount = upload.pageCount {
                        query.append(.init(name: "pageCount", value: String(pageCount)))
                    }
                    let form = MultipartFormData(parts: [
                        .init(name: "file", fileName: upload.fileName, mimeType: upload.contentType, data: upload.data)
                    ])
                    let request = NetworkRequest.multipart(path: "/api/v1/portfolios", queryItems: query, form: form)
                    return try await network.api(request)
                }
            },
            status: { portfolioId in
                try await mappingPortfolioError {
                    try await network.api(NetworkRequest(path: "/api/v1/portfolios/\(portfolioId.uuidString)/status"))
                }
            },
            delete: { portfolioId in
                try await mappingPortfolioError {
                    try await network.api(
                        NetworkRequest(method: .delete, path: "/api/v1/portfolios/\(portfolioId.uuidString)")
                    )
                }
            }
        )
    }
}

private struct PortfolioListPayload: Decodable, Sendable {
    let portfolios: [Portfolio]
}

// MARK: - 에러 매핑

/// 인프라 에러(ServerError·NetworkError)를 State 가 반응할 도메인 에러(PortfolioError)로 좁힌다.
/// 취소는 실패가 아니므로 그대로 통과시킨다 (TCA `.run` 이 조용히 무시).
private func mappingPortfolioError<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw PortfolioError(mapping: error)
    }
}

private extension PortfolioError {
    /// 서버 에러 코드 → 고정 케이스 (Portfolio 는 문구 노출형 검증군이 없다 — 전부 고정 매핑).
    static let serverCodeMap: [String: PortfolioError] = [
        "INVALID_FILE_TYPE": .invalidFileType,
        "FILE_TOO_LARGE": .fileTooLarge,
        "PAGE_COUNT_EXCEEDED": .pageCountExceeded,
        "INVALID_PDF_FILE": .invalidPDFFile,
        "PORTFOLIO_ALREADY_EXISTS": .alreadyExists,
        "PORTFOLIO_NOT_FOUND": .notFound,
        "LOGIN_EXPIRED": .sessionExpired,
        "TOKEN_EXPIRED": .sessionExpired,
        "INVALID_TOKEN": .sessionExpired
    ]

    init(mapping error: any Error) {
        switch error {
        case let error as PortfolioError:
            self = error
        case let error as ServerError:
            self = Self.serverCodeMap[error.code]
                ?? (error.statusCode >= 500 ? .serverUnavailable : .unexpected)
        case is NotAuthenticatedError:
            self = .sessionExpired
        case let error as NetworkError:
            self.init(networkError: error)
        default:
            self = .unexpected
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
