//
//  UserClientLiveTests.swift
//  DomainUserTests
//
//  Created by EunseoKim on 26/07/23.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainUserInterface
import XCTest
@testable import DomainUserImplementation

final class UserClientLiveTests: XCTestCase {
    private func makeClient(
        handler: @escaping @Sendable (NetworkRequest) async throws -> Data
    ) -> UserClient {
        withDependencies {
            $0.authorizedNetworkClient = AuthorizedNetworkClient(
                request: handler,
                authorizedResource: { _ in AuthorizedResource(url: URL(string: "stub://")!, headers: [:]) }
            )
        } operation: {
            UserClient.liveValue
        }
    }

    func test_profile_envelope을_벗겨_디코딩한다() async throws {
        let json = """
        {"success": true, "data": {
            "name": "히릿", "jobRole": "BACKEND", "jobRoleLabel": "백엔드",
            "careerYears": 3, "remainingTicketCount": 2
        }}
        """
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/users/me/profile")
            XCTAssertEqual(request.method, .get)
            return Data(json.utf8)
        }

        let profile = try await client.profile()

        XCTAssertEqual(profile.name, "히릿")
        XCTAssertEqual(profile.remainingTicketCount, 2)
    }

    func test_checkName_query로_이름을_싣고_available을_돌려준다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/users/name/check")
            XCTAssertEqual(request.queryItems, [URLQueryItem(name: "name", value: "히릿")])
            return Data(#"{"success": true, "data": {"available": false}}"#.utf8)
        }

        let available = try await client.checkName("히릿")

        XCTAssertFalse(available)
    }

    func test_registerName_이름중복409를_nameAlreadyTaken으로_매핑한다() async throws {
        let client = makeClient { _ in
            throw NetworkError.statusCode(409, Data(
                #"{"success": false, "code": "NAME_ALREADY_TAKEN", "message": "이미 사용 중인 이름이에요."}"#.utf8
            ))
        }

        do {
            try await client.registerName("히릿")
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? UserError, .nameAlreadyTaken)
        }
    }
}
