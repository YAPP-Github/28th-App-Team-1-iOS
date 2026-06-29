//
//  ProfileFeatureTests.swift
//  ProfileFeatureTests
//

import ComposableArchitecture
import XCTest

@testable import FeatureProfile

@MainActor
final class ProfileFeatureTests: XCTestCase {
    func test_init_assignsProfileId() {
        let state = ProfileFeature.State(profileId: 42)
        XCTAssertEqual(state.profileId, 42)
    }
}
