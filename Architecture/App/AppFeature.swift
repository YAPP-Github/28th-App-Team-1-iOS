import ComposableArchitecture
import Foundation

/// 앱 최상위 Reducer 겸 Coordinator.
///
/// - 자식 도메인: ``UserListFeature`` 한 개를 루트로 보유.
/// - 화면 스택: ``Path-swift.enum`` 으로 정의되며 ``State/path`` 에서 관리.
/// - 화면 전환: View 가 아닌 이 Reducer 가 자식 delegate 를 받아 처리.
///
/// ### 새 화면을 추가하려면
/// 1. 새 Feature 의 Reducer/View 를 작성한다.
/// 2. ``Path-swift.enum`` 에 `case yourFeature(YourFeature)` 한 줄 추가.
/// 3. 아래 `body` 의 `Reduce` 클로저에서 어떤 delegate 에 어떻게 반응할지
///    `case let .path(.element(id: _, action: ...))` 한 줄로 라우팅.
/// 4. ``AppView`` 의 `destination` switch 에 새 case 한 줄 추가.
///
/// 자세한 절차는 `AddingFeature` 가이드와 `AddingFeatureTutorial` 튜토리얼 참조.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var userList = UserListFeature.State()
        /// 스택 기반 네비게이션 경로. ``Path-swift.enum`` 의 case 들이 차곡차곡 쌓인다.
        var path = StackState<Path.State>()
    }

    enum Action {
        case userList(UserListFeature.Action)
        case path(StackActionOf<Path>)
    }

    /// 푸시 가능한 모든 화면의 합집합.
    ///
    /// 새 화면을 추가할 때 손대야 하는 첫 번째 지점이다. 각 case 의 연관값에는
    /// 해당 Feature 타입을 그대로 적어주면 TCA 가 `State`/`Action` 을 합성해 준다.
    @Reducer
    enum Path {
        case detail(UserDetailFeature)
        case profile(ProfileFeature)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.userList, action: \.userList) {
            UserListFeature()
        }
        Reduce { state, action in
            switch action {
            // MARK: Case B — UserList 가 User 객체째로 던지면 detail push
            case let .userList(.delegate(.userTappedRow(user))):
                state.path.append(.detail(UserDetailFeature.State(user: user)))
                return .none

            // MARK: Case A — UserDetail 이 id 만 던지면 profile push
            case let .path(.element(id: _, action: .detail(.delegate(.editProfileTapped(id))))):
                state.path.append(.profile(ProfileFeature.State(profileId: id)))
                return .none

            // MARK: Case C — Profile 저장 결과를 받아 목록·상세 갱신 + pop
            case let .path(.element(id: _, action: .profile(.delegate(.profileSaved(profile))))):
                applyProfileUpdate(profile, to: &state)
                if !state.path.isEmpty {
                    state.path.removeLast()
                }
                return .none

            case .userList, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    /// Case C 의 본체. 저장된 ``Profile`` 을 ``UserListFeature/State/users`` 와
    /// 스택에 남아 있는 ``UserDetailFeature/State`` 양쪽에 반영한다.
    private func applyProfileUpdate(_ profile: Profile, to state: inout State) {
        if let index = state.userList.users.firstIndex(where: { $0.id == profile.id }) {
            state.userList.users[index].name = profile.displayName
            state.userList.users[index].bio = profile.bio
        }
        for id in state.path.ids {
            guard case .detail(var detail) = state.path[id: id], detail.user.id == profile.id else {
                continue
            }
            detail.user.name = profile.displayName
            detail.user.bio = profile.bio
            state.path[id: id] = .detail(detail)
        }
    }
}

extension AppFeature.Path.State: Equatable {}
