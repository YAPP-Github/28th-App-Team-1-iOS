//
//  FeatureMyPageTesting.swift
//  FeatureMyPageTesting
//
//  Created by 서정원 on 26/08/01.
//

import ComposableArchitecture
import FeatureMyPageImplementation

// FeatureMyPage 시안 값 픽스처 — 현재 소비처 없음(테스트는 도메인 픽스처를 직접 만들고, 프리뷰·Example 은 자체
// 픽스처를 쓴다). AppFeature 조립 슬라이스에서 화면을 세울 때 쓰려고 남겨 둔다.
// (D3: Feature 는 Interface 가 없으므로 Implementation 의 public 타입을 직접 참조한다.)

public extension MyPageFeature.Profile {
    /// Figma «MyPage_Main» 플레이스홀더 그대로.
    static let placeholder = Self(
        name: "{재원}",
        jobGroup: "iOS",
        careerLevel: "2년차",
        remainingTickets: 3,
        email: "jaewon****@kakao.com",
        provider: "KAKAO"
    )
}

public extension MyPageFeature.PortfolioFile {
    static let placeholder = Self(name: "{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb")
}

public extension IdentifiedArray where ID == MyPageFeature.Report.ID, Element == MyPageFeature.Report {
    /// Figma «MyPage_Main» 의 리포트 세 줄 — 정상 / 포트폴리오 삭제됨 / 생성 실패.
    static var placeholders: Self {
        [
            .init(
                id: 1,
                title: "iOS · 2년차 면접",
                date: "2026.07.02",
                time: "14:20",
                jobLevel: "iOS · 2년",
                portfolioName: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                jobDescription: "careers.skproptier.com/jobs/1024",
                canOpenReport: true,
                canRequestFeedback: true
            ),
            .init(
                id: 2,
                title: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                date: "2026.07.02",
                time: "14:20",
                note: "삭제된 포트폴리오",
                jobLevel: "iOS · 2년",
                portfolioName: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                jobDescription: "직접 입력함",
                canOpenReport: true
            ),
            .init(
                id: 3,
                title: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                date: "2026.07.02",
                time: "14:20",
                status: "생성 실패",
                jobLevel: "iOS · 2년",
                portfolioName: "홍길동 자기소개서_SK프롭티어 기업 면접.pdf",
                jobDescription: "-",
                detailError: "리포트 생성에 실패했어요 · 횟수는 차감되지 않았어요"
            )
        ]
    }
}
