//
//  AuthTermsFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture

// @lat: [[auth#가입 플로우]]
/// AuthTerms(A1) — 필수 동의 5종을 받는 화면. 첫 소셜 인증 직후 1회 진입.
/// 필수 5종 외 체크박스를 추가하지 않는다(PRD Part7 확정 — 마케팅 등 선택 동의 없음).
/// 제출은 delegate 로 코디네이터(AuthFeature)에 올린다 — 동의 제출 API(=계정 생성 확정)는 서버 계약(S-1) 확정 후 배선.
@Reducer
public struct AuthTermsFeature {
    /// 필수 동의 5종 — PRD Part7 A1. 순서가 화면 나열 순서다.
    public enum ConsentItem: String, CaseIterable, Equatable, Sendable, Identifiable {
        case age14
        case termsOfService
        case privacy
        case avRecording
        case overseasTransfer

        public var id: String { rawValue }

        /// 체크박스 행 라벨 — Figma 3768:16671 문구 그대로.
        public var title: String {
            switch self {
            case .age14: "(필수) 만 14세 이상입니다."
            case .termsOfService: "(필수) 서비스 이용약관 동의"
            case .privacy: "(필수) 개인정보 수집·이용 동의"
            case .avRecording: "(필수) 면접 영상·음성 촬영과 저장 동의"
            case .overseasTransfer: "(필수) 개인정보 국외 이전 동의"
            }
        }

        /// 전문 바텀시트 머리글 — 행 라벨의 «(필수)» 접두를 뗀 문서 이름.
        /// 시안에 실린 건 `termsOfService`(3768:17200 «서비스 이용 약관») 하나뿐이고 나머지는 그 형식을 따랐다.
        public var documentTitle: String {
            switch self {
            case .age14: "만 14세 이상 확인"
            case .termsOfService: "서비스 이용 약관"
            case .privacy: "개인정보 수집·이용 동의"
            case .avRecording: "면접 영상·음성 촬영과 저장 동의"
            case .overseasTransfer: "개인정보 국외 이전 동의"
            }
        }

        /// 전문 [보기] 제공 여부 — 만 14세는 자체 확인 체크만 있고 전문이 없다.
        public var hasDocument: Bool { self != .age14 }
    }

    @ObservableState
    public struct State: Equatable {
        /// 체크된 항목들 — 5종 전부 모여야 제출 활성.
        public var checked: Set<ConsentItem> = []
        /// 전문 바텀시트에 띄운 항목 — nil 이면 시트 없음 (`.hilitBottomSheet(item:)` 값 기반).
        public var presentedDocument: ConsentItem?
        /// 제출 진행 중 — 동의 제출 API 배선 시 사용.
        public var isSubmitting = false

        public var isAllChecked: Bool { checked.count == ConsentItem.allCases.count }
        public var isSubmitEnabled: Bool { isAllChecked && !isSubmitting }

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            /// 개별 항목 체크 토글.
            case userToggledConsent(ConsentItem)
            /// 전체 동의 토글 — 하나라도 빠져 있으면 전부 켜고, 전부 켜져 있으면 전부 끈다.
            case userToggledAllConsent
            /// 항목 [보기] — 전문 바텀시트 표출.
            case userTappedDocument(ConsentItem)
            /// 바텀시트 딤 탭 — 닫기.
            case userDismissedDocument
            /// [동의하고 시작하기].
            case userTappedAgree
            /// 닫기(X) — 중도 이탈. 계정 미생성, 재로그인 시 이 화면 재진입(서버 판정).
            case userTappedClose
        }

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 필수 5종 동의 완료 — 코디네이터가 다음(가입 온보딩)으로 전환.
            /// TODO(S-1): 동의 제출 API(계정 생성 확정 + 무료 3회 부여 + 이력 저장) 배선 — DomainAuth 확장.
            case agreed
            /// 중도 이탈 — 코디네이터가 A0(소셜 로그인)로 되돌린다.
            case closeRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.userToggledConsent(item)):
                if state.checked.contains(item) {
                    state.checked.remove(item)
                } else {
                    state.checked.insert(item)
                }
                return .none

            case .view(.userToggledAllConsent):
                state.checked = state.isAllChecked ? [] : Set(ConsentItem.allCases)
                return .none

            case let .view(.userTappedDocument(item)):
                guard item.hasDocument else { return .none }
                state.presentedDocument = item
                return .none

            case .view(.userDismissedDocument):
                state.presentedDocument = nil
                return .none

            case .view(.userTappedAgree):
                guard state.isSubmitEnabled else { return .none }
                return .send(.delegate(.agreed))

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case .delegate:
                return .none
            }
        }
    }
}
