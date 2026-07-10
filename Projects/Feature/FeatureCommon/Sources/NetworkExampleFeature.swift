//
//  NetworkExampleFeature.swift
//  FeatureCommonImplementation
//
//  Created by EunseoKim on 26/07/10.
//

import ComposableArchitecture
import DomainInterviewInterface
import Foundation

// @lat: [[domain.map#네트워킹 인프라]]
// 네트워크 통신 화면의 표준형(템플릿) — Feature 는 Domain Client(InterviewClient)만 안다.
// NetworkClient/URLSession 은 여기서 보이지 않는 게 정상이다 (Domain Implementation 뒤로 숨는다).
@Reducer
public struct NetworkExampleFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        public var interviews: [Interview] = []
        public var errorMessage: String?

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        public enum View: Sendable {
            case onAppear
            case userTappedRetry
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        /// @CasePathable — 테스트가 `receive(\.inner.interviewsLoaded.success)` 로 정밀 매칭하기 위함.
        @CasePathable
        public enum Inner: Sendable {
            case interviewsLoaded(Result<[Interview], any Error>)
        }

        /// 부모(AppFeature) 통보. 부모는 이것만 매칭한다 (D1). 이 화면은 통보할 게 없어 비어 있다.
        public enum Delegate: Sendable {}
    }

    private enum CancelID { case fetch }

    @Dependency(\.interviewClient) var interviewClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear), .view(.userTappedRetry):
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    await send(.inner(.interviewsLoaded(
                        Result { try await interviewClient.fetchInterviews() }
                    )))
                }
                .cancellable(id: CancelID.fetch, cancelInFlight: true)

            case let .inner(.interviewsLoaded(.success(interviews))):
                state.isLoading = false
                state.interviews = interviews
                return .none

            case .inner(.interviewsLoaded(.failure)):
                // Feature 는 CoreNetwork(NetworkError)를 모른다 — 서버 에러코드 구분이 필요해지면
                // Domain 이 도메인 에러로 매핑해 계약에 실어준다.
                state.isLoading = false
                state.errorMessage = "면접 목록을 불러오지 못했어요."
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
