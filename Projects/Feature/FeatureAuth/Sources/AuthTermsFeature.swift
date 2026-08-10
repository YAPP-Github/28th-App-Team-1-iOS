//
//  AuthTermsFeature.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

import ComposableArchitecture
import DomainCommonInterface
import DomainConsentInterface

// @lat: [[auth#가입 플로우]]
/// AuthTerms(A1) — 동의가 필요한 항목을 받아 제출하는 화면. 최초 동의(신규)와 약관 개정 재동의가
/// 같은 화면이다 — 차이는 `pending` 이 내려주는 항목뿐(최초 = 필수 5종 전체, 재동의 = 바뀐 항목만).
/// 제출(`ConsentClient.submit`)까지 여기서 마치고 성공만 delegate 로 코디네이터(AuthFeature)에 올린다.
@Reducer
public struct AuthTermsFeature {
    @ObservableState
    public struct State: Equatable {
        /// 동의받을 항목 — nil 이면 진입 시 조회한다. 세션 복구(Splash) 경로는 판정이 이미 조회한
        /// pending 을 주입해 재호출을 던다 (docs/work/launch-routing.md).
        public var items: [ConsentItem]?
        /// 항목 조회 실패 — 목록 자리에 재시도를 노출한다.
        public var loadFailed = false
        /// 체크된 항목 코드들 — 필수 항목이 전부 모여야 제출 활성.
        public var checked: Set<String> = []
        /// 전문 바텀시트에 띄운 항목 — nil 이면 시트 없음 (`.hilitBottomSheet(item:)` 값 기반).
        public var presentedDocument: ConsentItem?
        /// 전문 본문 — 시트를 열 때마다 조회한다. nil 이면 로딩 중.
        public var documentContent: String?
        /// 제출 진행 중 — 이중 제출 방지.
        public var isSubmitting = false
        @Presents public var alert: AlertState<Action.Alert>?

        public var isAllChecked: Bool {
            guard let items, !items.isEmpty else { return false }
            return items.allSatisfy { checked.contains($0.code) }
        }
        /// 필수 전부 체크 시 활성 — 현행 항목은 필수 5종뿐이지만 서버가 선택 항목을 내려도 성립한다.
        public var isSubmitEnabled: Bool {
            guard let items, !items.isEmpty, !isSubmitting else { return false }
            return items.filter(\.isRequired).allSatisfy { checked.contains($0.code) }
        }

        public init(items: [ConsentItem]? = nil) {
            self.items = items
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Equatable, Sendable {
            /// 진입 — items 미주입(로그인 경로)이면 pending 을 조회한다.
            case onAppear
            /// 조회 실패 후 재시도.
            case userTappedRetryLoad
            /// 개별 항목 체크 토글.
            case userToggledConsent(ConsentItem)
            /// 전체 동의 토글 — 하나라도 빠져 있으면 전부 켜고, 전부 켜져 있으면 전부 끈다.
            case userToggledAllConsent
            /// 항목 [보기] — 전문 바텀시트 표출 + 본문 조회.
            case userTappedDocument(ConsentItem)
            /// 바텀시트 닫힘 — 아래로 스와이프·딤 탭(시스템 시트가 닫은 걸 상태로 되돌린다).
            case userDismissedDocument
            /// [동의하고 시작하기] — 제출 effect.
            case userTappedAgree
            /// 닫기(X) — 중도 이탈. 미제출 상태 유지, 재진입 시 이 화면(서버 판정).
            case userTappedClose
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Sendable {
            case pendingLoaded(Result<ConsentPending, ConsentError>)
            case documentLoaded(Result<ConsentDocument, ConsentError>)
            case submitFinished(Result<Void, ConsentError>)
        }

        public enum Alert: Equatable {}

        /// 코디네이터(AuthFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 동의 제출 성공 — 코디네이터가 프로필 게이트(온보딩/홈)로 전환. 첫 제출은 서버가 무료 3회 부여.
            case agreed
            /// 중도 이탈 — 코디네이터가 A0(소셜 로그인)로 되돌린다.
            case closeRequested
        }
    }

    @Dependency(\.consentClient) var consentClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard state.items == nil else { return .none }
                return loadPending()

            case .view(.userTappedRetryLoad):
                state.loadFailed = false
                return loadPending()

            case let .view(.userToggledConsent(item)):
                if state.checked.contains(item.code) {
                    state.checked.remove(item.code)
                } else {
                    state.checked.insert(item.code)
                }
                return .none

            case .view(.userToggledAllConsent):
                state.checked = state.isAllChecked ? [] : Set((state.items ?? []).map(\.code))
                return .none

            case let .view(.userTappedDocument(item)):
                guard item.hasDocument else { return .none }
                state.presentedDocument = item
                state.documentContent = nil
                return .run { send in
                    do {
                        let document = try await consentClient.document(item.code, item.version)
                        await send(.inner(.documentLoaded(.success(document))))
                    } catch {
                        await send(.inner(.documentLoaded(.failure(error as? ConsentError ?? .unexpected))))
                    }
                }

            case .view(.userDismissedDocument):
                state.presentedDocument = nil
                return .none

            case .view(.userTappedAgree):
                guard state.isSubmitEnabled, let items = state.items else { return .none }
                state.isSubmitting = true
                // item·version 은 pending 이 내려준 값 그대로 — 필수는 전부 체크됐고, 선택은 체크 여부가 곧 응답.
                let submissions = items.map {
                    ConsentSubmission(item: $0.code, version: $0.version, agreed: state.checked.contains($0.code))
                }
                return .run { send in
                    do {
                        try await consentClient.submit(submissions)
                        await send(.inner(.submitFinished(.success(()))))
                    } catch {
                        await send(.inner(.submitFinished(.failure(error as? ConsentError ?? .unexpected))))
                    }
                }

            case .view(.userTappedClose):
                return .send(.delegate(.closeRequested))

            case let .inner(.pendingLoaded(.success(pending))):
                state.items = pending.items
                return .none

            case .inner(.pendingLoaded(.failure)):
                state.loadFailed = true
                return .none

            case let .inner(.documentLoaded(.success(document))):
                state.documentContent = document.content
                return .none

            case .inner(.documentLoaded(.failure)):
                state.documentContent = "전문을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                return .none

            case .inner(.submitFinished(.success)):
                state.isSubmitting = false
                return .send(.delegate(.agreed))

            case let .inner(.submitFinished(.failure(error))):
                state.isSubmitting = false
                // 제출 사이 약관 개정(versionMismatch) — 항목·버전을 새로 받고 체크를 되돌린다.
                if error == .versionMismatch {
                    state.items = nil
                    state.checked = []
                    state.alert = AlertState(
                        title: { TextState("약관이 개정되었어요. 다시 확인해주세요.") },
                        actions: { ButtonState(role: .cancel) { TextState("확인") } }
                    )
                    return loadPending()
                }
                // 미승격 서버 에러는 공통 Alert 로 — title «CODE(status)», message 원문.
                if let serverAlert: AlertState<Action.Alert> = error.serverAlertState() {
                    state.alert = serverAlert
                    return .none
                }
                if case let .invalid(message) = error {
                    state.alert = AlertState(
                        title: { TextState(message) },
                        actions: { ButtonState(role: .cancel) { TextState("확인") } }
                    )
                    return .none
                }
                state.alert = AlertState(
                    title: { TextState("동의 제출에 실패했어요. 다시 시도해주세요.") },
                    actions: { ButtonState(role: .cancel) { TextState("확인") } }
                )
                return .none

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private func loadPending() -> Effect<Action> {
        .run { send in
            do {
                let pending = try await consentClient.pending()
                await send(.inner(.pendingLoaded(.success(pending))))
            } catch {
                await send(.inner(.pendingLoaded(.failure(error as? ConsentError ?? .unexpected))))
            }
        }
    }
}

// MARK: - 표시 문구 (Figma 3768:16671 — 서버 label 과 화면 카피가 달라 code 로 매핑)

extension ConsentItem {
    /// 체크박스 행 라벨. 시안 카피가 있는 항목은 그대로, 모르는 코드는 서버 label 로 합성한다.
    public var rowTitle: String {
        switch code {
        case "AGE_OVER_14": "(필수) 만 14세 이상입니다."
        case "TERMS_OF_SERVICE": "(필수) 서비스 이용약관 동의"
        case "PERSONAL_INFO_COLLECTION": "(필수) 개인정보 수집·이용 동의"
        case "INTERVIEW_RECORDING": "(필수) 면접 영상·음성 촬영과 저장 동의"
        case "OVERSEAS_TRANSFER": "(필수) 개인정보 국외 이전 동의"
        default: "(\(isRequired ? "필수" : "선택")) \(label) 동의"
        }
    }

    /// 전문 바텀시트 머리글 — 행 라벨의 «(필수)» 접두를 뗀 문서 이름.
    /// 시안에 실린 건 서비스 이용약관(3768:17200) 하나뿐이고 나머지는 그 형식을 따랐다.
    public var documentTitle: String {
        switch code {
        case "TERMS_OF_SERVICE": "서비스 이용 약관"
        default: label
        }
    }
}
