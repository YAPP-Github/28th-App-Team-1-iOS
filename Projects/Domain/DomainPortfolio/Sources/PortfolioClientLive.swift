//
//  PortfolioClientLive.swift
//  DomainPortfolioImplementation
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainCommonInterface
import DomainPortfolioInterface
import Foundation

// @lat: [[api#Portfolio]]
// depends-on: [[domain.map#네트워킹 인프라]]
extension PortfolioClient: @retroactive DependencyKey {
    public static var liveValue: PortfolioClient {
        @Dependency(\.authorizedNetworkClient) var network

        return PortfolioClient(
            list: {
                try await PortfolioError.mapping {
                    let payload: PortfolioListPayload = try await network.api(NetworkRequest(path: "/api/v1/portfolios"))
                    return payload.portfolios
                }
            },
            register: { upload in
                try await PortfolioError.mapping {
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
                try await PortfolioError.mapping {
                    try await network.api(NetworkRequest(path: "/api/v1/portfolios/\(portfolioId.uuidString)/status"))
                }
            },
            delete: { portfolioId in
                try await PortfolioError.mapping {
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
