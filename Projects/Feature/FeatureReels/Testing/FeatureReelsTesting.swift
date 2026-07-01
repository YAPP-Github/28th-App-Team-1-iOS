//
//  FeatureReelsTesting.swift
//  FeatureReelsTesting
//
//  Created by EunSeo on 26/07/02.
//

import ComposableArchitecture
import FeatureReelsImplementation

// FeatureReels 테스트 공용 지원 — 샘플 State 를 두고 Tests 타겟이 가져다 쓴다.
// (D3: Feature 는 Interface 가 없으므로 Implementation 의 public 타입을 직접 참조한다.)

public extension ReelsFeature.State {
    static var preview: Self { .sample() }
}
