import ComposableArchitecture
import Foundation

/// 프로필 편집 화면의 Reducer.
///
/// 이 Feature 는 **Case A — id 만 받아 화면에서 fetch** 패턴을 보여줍니다.
/// 상위에서 ``State/init(profileId:)`` 로 id 만 넘기면 ``Action/onAppear`` 가
/// ``ProfileClient/fetchProfile`` 를 호출해 본문을 채웁니다.
///
/// 저장이 끝나면 ``Action/Delegate/profileSaved(_:)`` 로 상위에 결과를 던지고,
/// 화면 pop 과 ``UserListFeature`` / ``UserDetailFeature`` 의 갱신은
/// ``AppFeature`` 가 일괄 처리합니다 (Case C — 결과 반환 delegate 패턴).
///
/// 폼 입력은 `BindableAction` + `BindingReducer` 패턴을 사용합니다.
/// View 에서는 `$store.editedDisplayName` 처럼 `@Bindable` 의 projected value 로
/// 바로 양방향 바인딩합니다.
@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable {
        let profileId: Int
        var profile: Profile?
        var isLoading = false
        var isSaving = false
        var errorMessage: String?
        var editedDisplayName: String = ""
        var editedBio: String = ""

        init(profileId: Int) {
            self.profileId = profileId
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case onDisappear
        case userTappedSaveButton
        case profileLoaded(Profile)
        case profileLoadingFailed(String)
        case profileSaved(Profile)
        case profileSaveFailed(String)
        case alertDismissed
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            /// 저장이 성공해 상위가 목록/상세를 갱신해야 함을 알리는 신호.
            case profileSaved(Profile)
        }
    }

    @Dependency(\.profileClient) var profileClient

    private enum CancelID { case load, save }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.profile == nil, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return .run { [id = state.profileId] send in
                    do {
                        let profile = try await profileClient.fetchProfile(id)
                        await send(.profileLoaded(profile))
                    } catch {
                        await send(.profileLoadingFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.load)

            case .onDisappear:
                return .merge(
                    .cancel(id: CancelID.load),
                    .cancel(id: CancelID.save)
                )

            case let .profileLoaded(profile):
                state.isLoading = false
                state.profile = profile
                state.editedDisplayName = profile.displayName
                state.editedBio = profile.bio
                return .none

            case let .profileLoadingFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .userTappedSaveButton:
                guard var draft = state.profile, !state.isSaving else { return .none }
                draft.displayName = state.editedDisplayName
                draft.bio = state.editedBio
                let pending = draft
                state.isSaving = true
                return .run { send in
                    do {
                        let saved = try await profileClient.saveProfile(pending)
                        await send(.profileSaved(saved))
                    } catch {
                        await send(.profileSaveFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.save)

            case let .profileSaved(profile):
                state.isSaving = false
                state.profile = profile
                return .send(.delegate(.profileSaved(profile)))

            case let .profileSaveFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none

            case .alertDismissed:
                state.errorMessage = nil
                return .none

            case .binding, .delegate:
                return .none
            }
        }
    }
}
