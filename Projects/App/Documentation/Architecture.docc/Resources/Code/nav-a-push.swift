// AppFeature — Users 의 신호를 받아 앱 레벨 sheet 로 Profile 제시 (id 만 전달).
// Profile 은 다른 Feature 라 UsersFeature 가 직접 push 하지 않는다.
case let .users(.delegate(.editProfile(id))):
    state.editProfile = ProfileFeature.State(profileId: id)
    return .none
