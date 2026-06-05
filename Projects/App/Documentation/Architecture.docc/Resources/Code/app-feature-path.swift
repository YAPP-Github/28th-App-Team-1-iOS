// AppFeature.State — 다른 Feature 는 @Presents 로 앱 레벨에서 제시한다.
@Presents public var editProfile: ProfileFeature.State?

// AppFeature.Action
case editProfile(PresentationAction<ProfileFeature.Action>)
