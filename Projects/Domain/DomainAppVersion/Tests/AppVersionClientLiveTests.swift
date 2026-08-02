//
//  AppVersionClientLiveTests.swift
//  DomainAppVersionTests
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainAppVersionInterface
import XCTest
@testable import DomainAppVersionImplementation

final class AppVersionClientLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> AppVersionClient {
        withDependencies {
            $0.networkClient = NetworkClient(request: handler)
        } operation: {
            AppVersionClient.liveValue
        }
    }

    func test_check_플랫폼과_버전을_query로_싣고_envelope을_벗겨_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "updateType": "FORCE", "latestVersion": "1.4.0",
            "minSupportedVersion": "1.3.0", "storeUrl": "https://apps.apple.com/app/id123"
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/app-versions/check")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.queryItems, [
                URLQueryItem(name: "platform", value: "IOS"),
                URLQueryItem(name: "version", value: "1.2.0")
            ])
            return Data(json.utf8)
        }

        let policy = try await client.check("1.2.0")

        XCTAssertEqual(policy.updateType, .force)
        XCTAssertEqual(policy.latestVersion, "1.4.0")
        XCTAssertEqual(policy.storeUrl, "https://apps.apple.com/app/id123")
    }

    func test_check_transport실패를_networkFailure로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.transport(.notConnectedToInternet)
        }

        do {
            _ = try await client.check("1.2.0")
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? AppVersionError, .networkFailure)
        }
    }
}
