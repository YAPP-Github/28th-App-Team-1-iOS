//
//  PortfolioClientMock.swift
//  DomainPortfolioTesting
//
//  Created by EunseoKim on 26/07/18.
//

import DomainPortfolioInterface
import Foundation

public extension PortfolioClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — READY 포트폴리오 1건의 해피패스를 돌려준다.
    static var mock: PortfolioClient {
        let sampleId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return PortfolioClient(
            list: {
                PortfolioList(portfolios: [
                    Portfolio(
                        portfolioId: sampleId,
                        fileName: "portfolio.pdf",
                        fileSize: 1_048_576,
                        pageCount: 12,
                        status: .ready,
                        uploadedAt: Date(timeIntervalSince1970: 1_782_000_000)
                    )
                ])
            },
            register: { _ in
                PortfolioProcessing(portfolioId: sampleId, status: .processing, message: nil)
            },
            status: { id in
                PortfolioProcessing(portfolioId: id, status: .ready, message: nil)
            },
            delete: { id in
                PortfolioDeletion(portfolioId: id, deletedAt: Date(timeIntervalSince1970: 1_782_000_000))
            }
        )
    }
}
