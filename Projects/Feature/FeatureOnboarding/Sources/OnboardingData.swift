//
//  OnboardingData.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainInterviewInterface
import Foundation

/// STEP 3 이 수집한 JD — 링크/직접입력 상호 배타를 타입으로 보장한다.
/// 도메인 `JobDescriptionInput`(.url/.text)과 1:1 로 대응한다.
public enum JDSubmission: Codable, Equatable, Sendable {
    /// 검증 성공한 채용공고 URL
    case link(String)
    /// 직접 입력한 JD 본문
    case text(String)
}

// @lat: [[onboarding#수집 데이터]]
/// 온보딩 위저드가 스텝을 거치며 채우는 공유 페이로드.
/// 코디네이터(OnboardingFeature)가 소유하고, 각 스텝의 delegate 결과를 여기에 누적한다.
/// 분석 스텝(STEP 6)이 이 값을 서버 제출 페이로드로 변환한다.
public struct OnboardingData: Codable, Equatable, Sendable {
    /// 타이틀 등에 쓰는 닉네임 — 진입 시 코디네이터(AppFeature)가 주입.
    public var userName: String
    /// STEP 1 직군 선택 결과 — 서버 enum 값(예: "BACKEND"). 미선택 시 nil.
    public var jobRole: String?
    /// STEP 2 연차 입력 결과 — 정수 연차(년). 그대로 `InterviewConfig.careerYears`.
    public var careerYears: Int?
    /// STEP 3 JD 결과 — 스킵 시 nil.
    public var jd: JDSubmission?
    /// STEP 4 포트폴리오 업로드 결과 — 서버 등록 완료된 포트폴리오 id.
    public var portfolioId: UUID?
    /// STEP 4 업로드한 파일명 — draft 복원 시 완료 행 재구성에 쓴다.
    public var portfolioFileName: String?
    /// STEP 5 집중 프로젝트 설명(선택) — DomainInterview 의 InterviewConfig.freeText 대응.
    public var freeText: String?

    public init(
        userName: String = "",
        jobRole: String? = nil,
        careerYears: Int? = nil,
        jd: JDSubmission? = nil,
        portfolioId: UUID? = nil,
        portfolioFileName: String? = nil,
        freeText: String? = nil
    ) {
        self.userName = userName
        self.jobRole = jobRole
        self.careerYears = careerYears
        self.jd = jd
        self.portfolioId = portfolioId
        self.portfolioFileName = portfolioFileName
        self.freeText = freeText
    }
}

// MARK: - 입력 draft (PRD §4.4)

/// 로컬 저장 draft — 앱 진짜 종료(kill/크래시) 시 재입력 방지용. TTL 판정은 코디네이터가 `savedAt` 으로 한다.
/// `furthestStep` 은 재개 지점(도달한 최상단 스텝, 1~6) — 재구성 시 이 단계까지 위저드를 되쌓는다.
public struct OnboardingDraft: Codable, Equatable, Sendable {
    public var data: OnboardingData
    public var furthestStep: Int
    public var savedAt: Date

    public init(data: OnboardingData, furthestStep: Int, savedAt: Date) {
        self.data = data
        self.furthestStep = furthestStep
        self.savedAt = savedAt
    }
}

/// 온보딩 입력 draft 의 로컬 영속 seam (UserDefaults). 서버 무관.
/// TODO: 로컬 IO 는 Domain/Core 가 원칙이나 [[onboarding#포트폴리오 업로드]] PortfolioFileReader 와 같은 선상에서 임시로 Feature 에 둔다.
public struct OnboardingDraftStore: Sendable {
    public var load: @Sendable () -> OnboardingDraft?
    public var save: @Sendable (OnboardingDraft) -> Void
    public var clear: @Sendable () -> Void

    public init(
        load: @escaping @Sendable () -> OnboardingDraft?,
        save: @escaping @Sendable (OnboardingDraft) -> Void,
        clear: @escaping @Sendable () -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

extension OnboardingDraftStore: DependencyKey {
    private static let key = "onboarding.draft.v1"

    public static var liveValue: OnboardingDraftStore {
        OnboardingDraftStore(
            load: {
                guard let raw = UserDefaults.standard.data(forKey: key),
                      let draft = try? JSONDecoder().decode(OnboardingDraft.self, from: raw)
                else { return nil }
                return draft
            },
            save: { draft in
                guard let raw = try? JSONEncoder().encode(draft) else { return }
                UserDefaults.standard.set(raw, forKey: key)
            },
            clear: { UserDefaults.standard.removeObject(forKey: key) }
        )
    }

    public static var testValue: OnboardingDraftStore {
        OnboardingDraftStore(
            load: unimplemented("OnboardingDraftStore.load", placeholder: nil),
            save: unimplemented("OnboardingDraftStore.save"),
            clear: unimplemented("OnboardingDraftStore.clear")
        )
    }
}

public extension DependencyValues {
    var onboardingDraftStore: OnboardingDraftStore {
        get { self[OnboardingDraftStore.self] }
        set { self[OnboardingDraftStore.self] = newValue }
    }
}

public extension OnboardingData {
    /// 분석 스텝의 세션 생성 입력(InterviewConfig)으로 변환한다 (PRD §3.8 — 개별 저장 없이 세션 생성이 S0~S3 일괄 수집).
    /// 필수 3종(직군·연차·포트폴리오)이 하나라도 없으면 nil — 위저드 순서상 분석 진입 시엔 항상 채워져 있다.
    /// 직군·연차는 존재 확인만 하고 payload 에서 뺀다 — 서버가 회원 프로필 스냅샷을 쓴다(2026-08-02 스펙).
    /// JD·집중 프로젝트는 nullable. JDSubmission(.link/.text) → JobDescriptionInput(.url/.text) 대응.
    func interviewConfig() -> InterviewConfig? {
        guard jobRole != nil, careerYears != nil, let portfolioId else { return nil }
        let jobDescription: JobDescriptionInput? = switch jd {
        case let .link(url): .url(url)
        case let .text(text): .text(text)
        case nil: nil
        }
        return InterviewConfig(
            portfolioId: portfolioId,
            jobDescription: jobDescription,
            freeText: freeText
        )
    }
}
