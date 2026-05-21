@ObservableState
struct State: Equatable {
    let profileId: Int
    var profile: Profile?
    var isLoading = false

    init(profileId: Int) { self.profileId = profileId }
}
