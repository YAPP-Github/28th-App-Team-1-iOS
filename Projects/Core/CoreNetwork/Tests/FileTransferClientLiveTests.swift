//
//  FileTransferClientLiveTests.swift
//  CoreNetworkTests
//
//  Created by 서정원 on 26/08/05.
//

import ComposableArchitecture
import CoreNetworkInterface
import Foundation
import XCTest
@testable import CoreNetworkImplementation

/// presigned PUT 계약 검증 — 절대 URL·무인증·Content-Type 원문 전달·2xx 가드.
final class FileTransferClientLiveTests: XCTestCase {
    private var client: FileTransferClient!
    private var fileURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        client = FileTransferClient.live(session: URLSession(configuration: configuration))
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("upload-fixture.mp4")
        try Data("video-bytes".utf8).write(to: fileURL)
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func test_PUT_메서드와_ContentType을_원문그대로_보내고_2xx면_정상반환한다() async throws {
        let captured = LockIsolated<URLRequest?>(nil)
        StubURLProtocol.handler = { request in
            captured.setValue(request)
            return (Self.httpResponse(for: request, statusCode: 200), Data())
        }

        try await client.upload(URL(string: "https://s3.test/video?sig=abc")!, "video/mp4", fileURL)

        XCTAssertEqual(captured.value?.httpMethod, "PUT")
        XCTAssertEqual(captured.value?.value(forHTTPHeaderField: "Content-Type"), "video/mp4")
        XCTAssertNil(captured.value?.value(forHTTPHeaderField: "Authorization"))   // 무인증 계약
    }

    func test_non2xx는_statusCode에러로_정규화한다() async {
        StubURLProtocol.handler = { request in
            (Self.httpResponse(for: request, statusCode: 403), Data("denied".utf8))
        }

        do {
            try await client.upload(URL(string: "https://s3.test/video")!, "video/mp4", fileURL)
            XCTFail("statusCode 에러가 나야 한다")
        } catch let error as NetworkError {
            guard case .statusCode(403, _) = error else { return XCTFail("403 statusCode 여야 한다: \(error)") }
        } catch {
            XCTFail("NetworkError 가 아니라 \(error)")
        }
    }

    func test_transport실패_URLError를_NetworkError로_정규화한다() async {
        StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            try await client.upload(URL(string: "https://s3.test/video")!, "video/mp4", fileURL)
            XCTFail("transport 에러가 나야 한다")
        } catch {
            XCTAssertEqual(error as? NetworkError, .transport(.notConnectedToInternet))
        }
    }

    private static func httpResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
