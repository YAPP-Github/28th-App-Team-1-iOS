//
//  FeatureGuestFeedbackTesting.swift
//  FeatureGuestFeedbackTesting
//
//  Created by 서정원 on 26/07/21.
//

import ComposableArchitecture
import FeatureGuestFeedbackImplementation

// FeatureGuestFeedback 테스트 공용 지원 — 샘플 State·목 데이터를 두고 Tests 타겟이 가져다 쓴다.
// (D3: Feature 는 Interface 가 없으므로 Implementation 의 public 타입을 직접 참조한다.)
//
// 예시 — 샘플 State:
//   public extension GuestFeedbackFeature.State {
//       static var preview: Self { .init() }
//   }
