//
//  UsersFeatureTests.swift
//  UsersFeatureTests
//

import ComposableArchitecture
import Models
import XCTest

@testable import UsersFeature

@MainActor
final class UsersFeatureTests: XCTestCase {
    func test_init_emptyPath() {
        let state = UsersFeature.State()
        XCTAssertTrue(state.path.isEmpty)
    }

    func test_listRowTapped_pushesDetail() async {
        let store = TestStore(initialState: UsersFeature.State()) {
            UsersFeature()
        } withDependencies: {
            $0.userClient = .previewValue
        }

        let user = User(id: 1, name: "Ada Lovelace", email: "ada@example.com")
        await store.send(.list(.delegate(.userTappedRow(user)))) {
            $0.path.append(.detail(UserDetailFeature.State(user: user)))
        }
    }
}
