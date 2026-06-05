// AppView — Profile 은 push 가 아니라 앱 레벨 sheet 로 제시
.sheet(item: $store.scope(state: \.editProfile, action: \.editProfile)) { store in
    NavigationStack {
        ProfileView(store: store)
    }
}
