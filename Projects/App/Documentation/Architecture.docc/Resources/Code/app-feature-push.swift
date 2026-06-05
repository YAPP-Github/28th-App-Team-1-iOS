// AppFeature.body — Users delegate 를 받아 제시 + 자식 reducer 연결
case let .users(.delegate(.editProfile(id))):
    state.editProfile = ProfileFeature.State(profileId: id)
    return .none
// ...
.ifLet(\.$editProfile, action: \.editProfile) {
    ProfileFeature()
}
