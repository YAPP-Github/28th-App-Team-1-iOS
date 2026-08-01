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
            "userId": "550e8400-e29b-41d4-a716-446655440000",
            "name": "히릿", "email": "hilit@kakao.com", "provider": "KAKAO",
            "jobRole": "BACKEND", "jobRoleLabel": "백엔드",
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
        XCTAssertEqual(profile.email, "hilit@kakao.com")
        XCTAssertEqual(profile.provider, "KAKAO")
        XCTAssertEqual(profile.remainingTicketCount, 2)
    }

    func test_updateProfile_세_필드를_body에_실어_PATCH한다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/users/me/profile")
            XCTAssertEqual(request.method, .patch)
            let body = try XCTUnwrap(request.body)
            let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(decoded?["name"] as? String, "히릿")
            XCTAssertEqual(decoded?["jobRole"] as? String, "BACKEND")
            XCTAssertEqual(decoded?["careerYears"] as? Int, 3)
            return Data(#"{"success": true}"#.utf8)
        }

        try await client.updateProfile(UserProfileUpdate(name: "히릿", jobRole: "BACKEND", careerYears: 3))
    }

    func test_withdraw_소셜연동정보없음409를_socialReconnectRequired로_매핑한다() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.path, "/api/v1/users/me")
            XCTAssertEqual(request.method, .delete)
            throw NetworkError.statusCode(409, Data(
                #"{"success": false, "code": "SOCIAL_RECONNECT_REQUIRED", "message": "소셜 연동 정보가 없어 탈퇴할 수 없습니다."}"#.utf8
            ))
        }

        do {
            try await client.withdraw()
            XCTFail("에러가 던져져야 한다")
        } catch {
            XCTAssertEqual(error as? UserError, .socialReconnectRequired)
        }
    }
}
