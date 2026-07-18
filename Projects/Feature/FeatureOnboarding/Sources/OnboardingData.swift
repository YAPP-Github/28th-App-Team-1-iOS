//
//  OnboardingData.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import Foundation

// @lat: [[onboarding#수집 데이터]]
/// 온보딩 위저드가 스텝을 거치며 채우는 공유 페이로드.
/// 코디네이터(OnboardingFeature)가 소유하고, 각 스텝의 delegate 결과를 여기에 누적한다.
/// 마지막 스텝에서 이 값을 서버 제출 페이로드로 변환한다.
public struct OnboardingData: Equatable, Sendable {
    /// 타이틀 등에 쓰는 닉네임 — 진입 시 코디네이터(AppFeature)가 주입.
    public var userName: String
    /// STEP 1 직군 선택 결과 — 서버 enum 값(예: "BACKEND"). 미선택 시 nil.
    public var jobRole: String?

    // 이후 스텝(경력·기술스택 등)이 붙을 때마다 필드를 추가한다.

    public init(userName: String = "", jobRole: String? = nil) {
        self.userName = userName
        self.jobRole = jobRole
    }
}
