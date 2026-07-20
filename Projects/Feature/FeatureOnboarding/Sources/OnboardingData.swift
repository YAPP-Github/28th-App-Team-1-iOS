//
//  OnboardingData.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import DomainInterviewInterface
import Foundation

/// STEP 3 이 수집한 JD — 링크/직접입력 상호 배타를 타입으로 보장한다.
/// 도메인 `JobDescriptionInput`(.url/.text)과 1:1 로 대응한다.
public enum JDSubmission: Equatable, Sendable {
    /// 검증 성공한 채용공고 URL
    case link(String)
    /// 직접 입력한 JD 본문
    case text(String)
}

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
    /// STEP 3 JD 결과 — 스킵 시 nil.
    public var jd: JDSubmission?
    /// STEP 4 포트폴리오 업로드 결과 — 서버 등록 완료된 포트폴리오 id.
    public var portfolioId: UUID?
    /// STEP 5 집중 프로젝트 설명(선택) — DomainInterview 의 InterviewConfig.freeText 대응.
    public var freeText: String?

    public init(
        userName: String = "",
        jobRole: String? = nil,
        career: CareerOption? = nil,
        jd: JDSubmission? = nil,
        portfolioId: UUID? = nil,
        freeText: String? = nil
    ) {
        self.userName = userName
        self.jobRole = jobRole
        self.career = career
        self.jd = jd
        self.portfolioId = portfolioId
        self.freeText = freeText
    }
}

public extension OnboardingData {
    /// 분석 스텝의 세션 생성 입력(InterviewConfig)으로 변환한다 (PRD §3.8 — 개별 저장 없이 세션 생성이 S0~S3 일괄 수집).
    /// 필수 3종(직군·연차·포트폴리오)이 하나라도 없으면 nil — 위저드 순서상 분석 진입 시엔 항상 채워져 있다.
    /// JD·집중 프로젝트는 nullable. JDSubmission(.link/.text) → JobDescriptionInput(.url/.text) 대응.
    func interviewConfig() -> InterviewConfig? {
        guard let jobRole, let career, let portfolioId else { return nil }
        let jobDescription: JobDescriptionInput? = switch jd {
        case let .link(url): .url(url)
        case let .text(text): .text(text)
        case nil: nil
        }
        return InterviewConfig(
            portfolioId: portfolioId,
            jobRole: jobRole,
            careerYears: career.careerYears,
            jobDescription: jobDescription,
            freeText: freeText
        )
    }
}
