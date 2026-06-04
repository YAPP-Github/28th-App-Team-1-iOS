//
//  UserFeatureTests.swift
//  UserFeatureTests
//

import ComposableArchitecture
import XCTest

@testable import UserFeature

@MainActor
final class UserFeatureTests: XCTestCase {
    func test_init_emptyPath() {
        let state = UserFeature.State()
        XCTAssertTrue(state.path.isEmpty)
    }
}
