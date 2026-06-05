// AppFeature — 저장 결과를 받아 sheet 닫고 Users 도메인에 통보
case let .editProfile(.presented(.delegate(.profileSaved(profile)))):
    state.editProfile = nil
    return .send(.users(.profileUpdated(profile)))

// UsersFeature — 목록 + 스택에 남은 상세 양쪽을 갱신
case let .profileUpdated(profile):
    applyProfileUpdate(profile, to: &state)
    return .none
