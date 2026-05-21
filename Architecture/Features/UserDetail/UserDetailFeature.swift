import ComposableArchitecture
import Foundation

/// 사용자 상세 화면 Reducer.
///
/// 이 Feature 는 **Case B — 객체 전체 전달** 패턴의 예시입니다.
/// 상위 ``AppFeature`` 가 `State(user:)` 에 ``User`` 통째로 넘기기 때문에
/// 화면 진입 즉시 이름·이메일을 보여줄 수 있고, bio 만 ``Action/onAppear`` 에서
/// 추가로 fetch 합니다 (실서비스에서는 detail 전용 endpoint 가 따로 있는 경우).
///
/// 편집 화면 진입은 ``Action/Delegate/editProfileTapped(id:)`` 로 위에 알리고,
/// 실제 push 는 ``AppFeature`` 가 처리합니다 — Feature 가 직접 자기 위 스택을
/// 만지지 않는 원칙입니다.
@Reducer
struct UserDetailFeature {
    @ObservableState
    struct State: Equatable {
        var user: User
        var isLoading = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case onDisappear
        case userTappedEditButton
        case userDetailLoaded(User)
        case userLoadingFailed(String)
        case alertDismissed
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            /// "Edit Profile" 버튼이 눌렸음을 상위에 알리고, 어떤 id 를 편집할지 함께 전달.
            case editProfileTapped(id: Int)
        }
    }

    @Dependency(\.userClient) var userClient

    private enum CancelID { case load }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [id = state.user.id] send in
                    do {
                        let user = try await userClient.fetchUser(id)
                        await send(.userDetailLoaded(user))
                    } catch {
                        await send(.userLoadingFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.load)

            case .onDisappear:
                return .cancel(id: CancelID.load)

            case let .userDetailLoaded(user):
                state.isLoading = false
                state.user.bio = user.bio
                return .none

            case let .userLoadingFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .userTappedEditButton:
                return .send(.delegate(.editProfileTapped(id: state.user.id)))

            case .alertDismissed:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
