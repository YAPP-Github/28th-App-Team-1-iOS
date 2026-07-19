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
/// 분석 스텝(STEP 6)이 이 값을 서버 제출 페이로드로 변환한다.
public struct OnboardingData: Equatable, Sendable {
    /// 타이틀 등에 쓰는 닉네임 — 진입 시 코디네이터(AppFeature)가 주입.
    public var userName: String
    /// STEP 1 직군 선택 결과 — 서버 enum 값(예: "BACKEND"). 미선택 시 nil.
    public var jobRole: String?
    /// STEP 2 연차 입력 결과. 서버 enum 미정 — rawValue 임시.
    public var career: CareerOption?
    /// STEP 3 JD 링크 결과 — 링크 제출 시. jdText 와 상호 배타, 스킵 시 둘 다 nil.
    public var jdLink: String?
    /// STEP 3 JD 직접입력 결과 — 텍스트 제출 시.
    public var jdText: String?
    /// STEP 4 포트폴리오 업로드 결과 — 서버 등록 완료된 포트폴리오 id.
    public var portfolioId: UUID?
    /// STEP 5 집중 프로젝트 설명(선택) — DomainInterview 의 InterviewConfig.freeText 대응.
    public var freeText: String?

    public init(
        userName: String = "",
        jobRole: String? = nil,
        career: CareerOption? = nil,
        jdLink: String? = nil,
        jdText: String? = nil,
        portfolioId: UUID? = nil,
        freeText: String? = nil
    ) {
        self.userName = userName
        self.jobRole = jobRole
        self.career = career
        self.jdLink = jdLink
        self.jdText = jdText
        self.portfolioId = portfolioId
        self.freeText = freeText
    }
}
