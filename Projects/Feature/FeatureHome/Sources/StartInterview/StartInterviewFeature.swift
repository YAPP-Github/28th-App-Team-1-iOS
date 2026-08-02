//
//  StartInterviewFeature.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import DomainPortfolioInterface
import Foundation

// @lat: [[home]]
/// 면접 시작 — 홈 씬에서 리포트 시트 뒤에 깔리는 한 겹. 시안 3장을 `Variant` 로 분기한다.
///
/// 홈의 phase 가 아니라 별도 Reducer 인 이유: 홈 상태의 표시가 아니라 «면접을 시작할까» 를 묻는
/// 별도 화면이고, 응답(시작·수정)은 홈이 처리할 수 없는 cross-feature 전환이라 delegate 로 올라간다.
///
/// 나가기는 여기 없다 — 이 겹을 덮는 건 «시트를 도로 올린다» 라서 홈의 자리(`SheetDetent`) 몫이다.
/// 하단 «홈으로» 만 delegate 로 올린다(CTA 는 이 화면 소유라서).
@Reducer
public struct StartInterviewFeature {
    /// 시안 3종 — 처음 / 등록 포폴 있음 / 무료 횟수 모두 사용.
    public enum Variant: Equatable, Sendable {
        case first
        case hasPortfolio
        case exhausted
    }

    /// 등록된 포트폴리오 표시값 — 카드 한 줄에 들어가는 원값만 담는다.
    /// **포맷팅은 뷰 몫**이다(«2026.07.31»·«3.2mb» 같은 표기는 시안 소유).
    /// 날짜·용량이 옵셔널인 건 서버 응답이 그렇기 때문이다 — 없으면 뷰가 그 조각만 뺀다
    /// («0.0mb»·«1970.01.01» 같은 가짜 값을 만들지 않는다).
    public struct Portfolio: Equatable, Sendable {
        public var fileName: String
        public var uploadedAt: Date?
        public var byteCount: Int?

        public init(fileName: String, uploadedAt: Date?, byteCount: Int?) {
            self.fileName = fileName
            self.uploadedAt = uploadedAt
            self.byteCount = byteCount
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 표시할 시안 변형 — 홈 진입 로드 결과로 홈이 정한다(잔여 0 이면 소진, 포폴 있으면 재사용).
        public var variant: Variant
        /// 인사말에 넣는 사용자 이름 — 홈이 프로필 로드 결과를 그대로 내려 준다.
        /// 응답 전엔 비어 있고, 그때는 뷰가 이름 줄을 뺀다(사람 이름을 기본값으로 두지 않는다).
        public var userName: String
        /// 남은 무료 면접 횟수 — 서버 값 표시만(«진실은 서버에만», docs/work/home-account.md §3).
        /// **nil 은 «아직 모른다»** 다(프로필 응답 전·실패). 0 과 갈라 둬야 로드 실패를 소진으로
        /// 오해하지 않는다 — 포폴 날짜·용량과 같은 규칙이다(없는 조각은 가짜 값 대신 뺀다).
        public var remainingChances: Int?
        /// 등록된 포트폴리오 — 없으면 nil(«이전 정보 재사용» 시안에서만 카드에 쓴다).
        public var portfolio: Portfolio?

        /// 기본값은 전부 중립이다 — `variant` 로 시안 값을 파생하지 않는다.
        /// 파생하면 프리뷰 픽스처(`Portfolio.placeholder` 의 «{파일명}.pdf», 조작된 잔여 3회)가
        /// 앱에서 그대로 그려진다. 시안대로 보고 싶은 프리뷰가 픽스처를 명시로 넘긴다.
        /// 잔여의 중립은 **0 이 아니라 nil** 이다 — 0 은 «소진» 이라는 서버 판정이라서.
        public init(
            variant: Variant,
            userName: String = "",
            remainingChances: Int? = nil,
            portfolio: Portfolio? = nil
        ) {
            self.variant = variant
            self.userName = userName
            self.remainingChances = remainingChances
            self.portfolio = portfolio
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            /// [시작하기] 탭.
            case userTappedStart
            /// [수정하기] 탭 — 이전 면접 정보를 고치고 시작한다.
            case userTappedEditInfo
            /// [홈으로] 탭 — 무료 횟수 소진 시안의 나가기 경로.
            case userTappedBackToHome
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        public enum Inner: Sendable {}

        /// 부모(HomeFeature) 통보. 부모는 이것만 매칭한다 (D1).
        public enum Delegate: Sendable {
            /// 면접 시작 요청 — 실제 전환은 홈 위로 AppFeature 가 조립한다.
            case startRequested
            /// 면접 정보 수정 요청 — 전환은 AppFeature.
            case editInfoRequested
            /// 홈으로 요청 — 소진 시안의 나가기(하단 CTA). 홈은 시트를 도로 올린다.
            case backToHomeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.userTappedStart):
                return .send(.delegate(.startRequested))
            case .view(.userTappedEditInfo):
                return .send(.delegate(.editInfoRequested))
            case .view(.userTappedBackToHome):
                return .send(.delegate(.backToHomeRequested))
            case .inner, .delegate:
                return .none
            }
        }
    }
}

// MARK: - 서버 값 → 표시값

extension StartInterviewFeature.Portfolio {
    /// 서버 포폴(`DomainPortfolio.Portfolio`) → 카드 표시값.
    /// 파일명이 없으면 그릴 줄 자체가 성립하지 않아 nil 이다(서버는 항상 주지만 응답 모델이 옵셔널).
    init?(portfolio: DomainPortfolioInterface.Portfolio) {
        guard let fileName = portfolio.fileName else { return nil }
        self.init(
            fileName: fileName,
            uploadedAt: portfolio.uploadedAt,
            byteCount: portfolio.fileSize
        )
    }
}

// MARK: - 시안 값

// `#if DEBUG` — 「프리뷰 전용」을 주석이 아니라 컴파일러가 지키게 한다.
// 릴리스 코드가 이걸 참조하면 그 빌드가 깨지므로 시안 픽스처가 앱에 새지 않는다.
#if DEBUG
extension StartInterviewFeature.Portfolio {
    /// 시안(3632:13730)의 파일 한 줄 — **프리뷰·시안 확인 전용** 픽스처다.
    /// 파일명은 시안 표기 그대로, 날짜·용량은 형이 붙어 표본값이다(포맷은 뷰가 만든다).
    public static let placeholder = Self(
        fileName: "{파일명}.pdf",
        // 2026-07-31 00:00 UTC — 프리뷰가 흔들리지 않게 고정값을 쓴다.
        uploadedAt: Date(timeIntervalSince1970: 1_785_456_000),
        byteCount: 3_355_443
    )
}
#endif
