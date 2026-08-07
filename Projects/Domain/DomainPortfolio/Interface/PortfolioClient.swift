//
//  PortfolioClient.swift
//  DomainPortfolioInterface
//
//  Created by EunseoKim on 26/07/18.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 처리 상태 — 등록 직후 PROCESSING, S3 업로드·파싱·임베딩 완료 시 READY.
public enum PortfolioProcessingStatus: String, Decodable, Equatable, Sendable {
    case processing = "PROCESSING"
    case ready = "READY"
    case failedFile = "FAILED_FILE"
    case failedSystem = "FAILED_SYSTEM"
}

/// 등록된 포트폴리오. MVP 는 계정당 1개 (응답은 다건 확장 대비 배열).
public struct Portfolio: Decodable, Equatable, Sendable, Identifiable {
    public let portfolioId: UUID
    public let fileName: String?
    /// 파일 크기(byte)
    public let fileSize: Int?
    public let pageCount: Int?
    public let status: PortfolioProcessingStatus?
    public let uploadedAt: Date?

    public var id: UUID { portfolioId }

    public init(
        portfolioId: UUID,
        fileName: String?,
        fileSize: Int?,
        pageCount: Int?,
        status: PortfolioProcessingStatus?,
        uploadedAt: Date?
    ) {
        self.portfolioId = portfolioId
        self.fileName = fileName
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.status = status
        self.uploadedAt = uploadedAt
    }
}

/// 목록 응답 — 등록 건 + 계정 단위 가용성 플래그.
/// 가용성은 **개별 포폴이 아니라 계정** 속성이라 `portfolios` 밖(= `data` 레벨)에 온다.
public struct PortfolioList: Decodable, Equatable, Sendable {
    public let portfolios: [Portfolio]
    /// 교체(재등록) 가능 여부
    public let replaceAvailable: Bool?
    /// 교체 불가일 때 다시 가능해지는 시각 (가능하면 nil)
    public let nextAvailableAt: Date?
    /// 삭제 가능 여부
    public let deleteAvailable: Bool?
    /// 삭제 불가일 때 다시 가능해지는 시각 (가능하면 nil)
    public let nextDeleteAvailableAt: Date?

    public init(
        portfolios: [Portfolio],
        replaceAvailable: Bool? = nil,
        nextAvailableAt: Date? = nil,
        deleteAvailable: Bool? = nil,
        nextDeleteAvailableAt: Date? = nil
    ) {
        self.portfolios = portfolios
        self.replaceAvailable = replaceAvailable
        self.nextAvailableAt = nextAvailableAt
        self.deleteAvailable = deleteAvailable
        self.nextDeleteAvailableAt = nextDeleteAvailableAt
    }
}

/// 업로드 입력 — PDF 20MB 이하 · 30페이지 이하 (서버 검증: `INVALID_FILE_TYPE`·`FILE_TOO_LARGE`·`PAGE_COUNT_EXCEEDED`).
public struct PortfolioUpload: Equatable, Sendable {
    public var fileName: String
    public var fileSize: Int?
    public var pageCount: Int?
    public var contentType: String
    /// PDF 바이너리
    public var data: Data

    public init(
        fileName: String,
        fileSize: Int? = nil,
        pageCount: Int? = nil,
        contentType: String = "application/pdf",
        data: Data
    ) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.contentType = contentType
        self.data = data
    }
}

/// 등록(202)·상태 폴링 공통 응답 — `{ portfolioId, status, message }`.
public struct PortfolioProcessing: Decodable, Equatable, Sendable {
    public let portfolioId: UUID
    public let status: PortfolioProcessingStatus
    /// 사용자에게 노출할 안내 메시지
    public let message: String?

    public init(portfolioId: UUID, status: PortfolioProcessingStatus, message: String?) {
        self.portfolioId = portfolioId
        self.status = status
        self.message = message
    }
}

/// 삭제 응답
public struct PortfolioDeletion: Decodable, Equatable, Sendable {
    public let portfolioId: UUID?
    public let deletedAt: Date?

    public init(portfolioId: UUID?, deletedAt: Date?) {
        self.portfolioId = portfolioId
        self.deletedAt = deletedAt
    }
}

// MARK: - Client

/// 포트폴리오 API (D14 `/api/v1/portfolios/**`).
/// 계정당 1개 제한 — 재등록은 `PORTFOLIO_ALREADY_EXISTS` → 삭제 후 등록 UX.
// @lat: [[api#Portfolio]]
public struct PortfolioClient: Sendable {
    /// GET /portfolios — 내 포트폴리오 목록 + 계정 단위 교체·삭제 가용성.
    public var list: @Sendable () async throws -> PortfolioList
    /// POST /portfolios — 202 PROCESSING 접수. 이후 `status` 폴링(3~5초)으로 READY 확인.
    public var register: @Sendable (PortfolioUpload) async throws -> PortfolioProcessing
    /// GET /portfolios/{id}/status — 처리 상태 폴링.
    public var status: @Sendable (_ portfolioId: UUID) async throws -> PortfolioProcessing
    /// DELETE /portfolios/{id}
    public var delete: @Sendable (_ portfolioId: UUID) async throws -> PortfolioDeletion

    public init(
        list: @escaping @Sendable () async throws -> PortfolioList,
        register: @escaping @Sendable (PortfolioUpload) async throws -> PortfolioProcessing,
        status: @escaping @Sendable (_ portfolioId: UUID) async throws -> PortfolioProcessing,
        delete: @escaping @Sendable (_ portfolioId: UUID) async throws -> PortfolioDeletion
    ) {
        self.list = list
        self.register = register
        self.status = status
        self.delete = delete
    }
}

extension PortfolioClient: TestDependencyKey {
    public static var testValue: PortfolioClient {
        PortfolioClient(
            list: unimplemented("PortfolioClient.list", placeholder: PortfolioList(portfolios: [])),
            register: unimplemented("PortfolioClient.register"),
            status: unimplemented("PortfolioClient.status"),
            delete: unimplemented("PortfolioClient.delete")
        )
    }

    public static var previewValue: PortfolioClient {
        let sampleId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return PortfolioClient(
            list: {
                PortfolioList(
                    portfolios: [
                        Portfolio(
                            portfolioId: sampleId,
                            fileName: "portfolio.pdf",
                            fileSize: 1_048_576,
                            pageCount: 12,
                            status: .ready,
                            uploadedAt: Date(timeIntervalSince1970: 1_782_000_000)
                        )
                    ],
                    replaceAvailable: true,
                    deleteAvailable: true
                )
            },
            register: { upload in
                PortfolioProcessing(portfolioId: sampleId, status: .processing, message: "\(upload.fileName) 분석을 시작했어요")
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

public extension DependencyValues {
    var portfolioClient: PortfolioClient {
        get { self[PortfolioClient.self] }
        set { self[PortfolioClient.self] = newValue }
    }
}
