import ComposableArchitecture
import Foundation
import Models
import ProfileClient

/// 프로필 편집 화면 Reducer.
///
/// **Case A** (id 만 받아 화면에서 fetch) 와 **Case C** (저장 결과를 delegate
/// 로 부모에 통보) 를 한 화면에 모두 보여주는 Feature.
@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        public let profileId: Int
        public var profile: Profile?
        public var isLoading: Bool
        public var isSaving: Bool
        public var errorMessage: String?
        public var editedDisplayName: String
        public var editedBio: String

        public init(profileId: Int) {
            self.profileId = profileId
            self.profile = nil
            self.isLoading = false
            self.isSaving = false
            self.errorMessage = nil
            self.editedDisplayName = ""
            self.editedBio = ""
        }
    }

    public enum Action: BindableAction {
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
        public enum Delegate: Equatable {
            /// 저장이 성공해 상위가 목록/상세를 갱신해야 함을 알리는 신호.
            case profileSaved(Profile)
        }
    }

    @Dependency(\.profileClient) var profileClient

    private enum CancelID { case load, save }

    public init() {}

    public var body: some ReducerOf<Self> {
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
