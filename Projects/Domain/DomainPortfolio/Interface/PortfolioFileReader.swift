//
//  PortfolioFileReader.swift
//  DomainPortfolioInterface
//
//  Created by 서정원 on 26/08/08.
//

import ComposableArchitecture
import Foundation

/// 선택한 PDF 의 바이트 + 클라 선검증용 메타(페이지 수·암호 여부).
/// 페이지 수는 파싱 실패 시 nil — 그 경우 서버 실측에 판정을 위임한다.
public struct PortfolioFile: Equatable, Sendable {
    /// PDF 바이너리
    public var data: Data
    /// PDF 페이지 수 — 파싱 불가(손상·비PDF) 시 nil.
    public var pageCount: Int?
    /// 열기 암호가 걸린 PDF 여부.
    public var isEncrypted: Bool

    public init(data: Data, pageCount: Int? = nil, isEncrypted: Bool = false) {
        self.data = data
        self.pageCount = pageCount
        self.isEncrypted = isEncrypted
    }
}

/// fileImporter 가 준 security-scoped URL 에서 PDF 바이트·메타를 읽는 파일 IO seam.
/// 서버 호출은 없지만 `register` 앞단의 선검증(20MB·30쪽·암호)을 위한 로컬 읽기라 업로드 파이프라인의 일부다.
/// 소비처는 둘 — 온보딩 S2 와 마이페이지 포폴 칸.
// @lat: [[api#Portfolio]]
public struct PortfolioFileReader: Sendable {
    public var read: @Sendable (URL) async throws -> PortfolioFile

    public init(read: @escaping @Sendable (URL) async throws -> PortfolioFile) {
        self.read = read
    }
}

extension PortfolioFileReader: TestDependencyKey {
    public static var testValue: PortfolioFileReader {
        PortfolioFileReader(read: unimplemented("PortfolioFileReader.read"))
    }
}

public extension DependencyValues {
    var portfolioFileReader: PortfolioFileReader {
        get { self[PortfolioFileReader.self] }
        set { self[PortfolioFileReader.self] = newValue }
    }
}
