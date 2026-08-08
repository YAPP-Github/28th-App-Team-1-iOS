//
//  PortfolioFileReaderLive.swift
//  DomainPortfolioImplementation
//
//  Created by 서정원 on 26/08/08.
//

import ComposableArchitecture
import DomainPortfolioInterface
import Foundation
import PDFKit

// @lat: [[api#Portfolio]]
extension PortfolioFileReader: @retroactive DependencyKey {
    public static var liveValue: PortfolioFileReader {
        PortfolioFileReader { url in
            let isScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isScoped { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            // PDFKit 파싱 — 페이지 수·암호 여부만 뽑는다(내용 추출·글자 수 판정은 서버 Tika).
            let document = PDFDocument(data: data)
            return PortfolioFile(
                data: data,
                pageCount: document?.pageCount,
                isEncrypted: document?.isEncrypted ?? false
            )
        }
    }
}
