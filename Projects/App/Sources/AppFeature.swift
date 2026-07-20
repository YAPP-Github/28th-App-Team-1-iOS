//
//  AppFeature.swift
//  Hilit
//
//  Created by 서정원 on 26/07/13.
//

import ComposableArchitecture
import CorePushInterface
import Feature

// @lat: [[app]]
// depends-on: [[auth]] — 로그인 전/후 루트 게이트. cross-feature 조립은 AppFeature 에서만.
// depends-on: [[home]] — Home 을 탭으로 임베드(owner). cross-feature delegate 라우팅은 Feature 추가 시 이 자리에서 조립.
// depends-on: [[domain.map#푸시 인프라]] — 푸시 스트림의 단일 소비자. 배선 순서는 [[app#푸시 배선]].
@Reducer
struct AppFeature {
    /// 탭 식별자. 새 탭 추가 시: 여기 case → State 프로퍼티 → body Scope → AppView tabItem 순으로 확장.
    enum Tab: Hashable {
        case home
    }

    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        /// 로그인 게이트. 토큰 영속화가 없으므로 앱 재실행 시 항상 false에서 시작(의도된 범위 제한).
        var isAuthenticated = false
        var home = HomeFeature.State()
        var selectedTab: Tab = .home
    }

    enum Action: BindableAction {
        case onAppear
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
        case binding(BindingAction<State>)
        /// FCM registration token 발급/갱신 — 백엔드 디바이스 토큰 등록의 입력(연결은 TODO).
        case fcmTokenUpdated(String)
        /// 푸시 수신/탭 이벤트 — 알림 탭 라우팅의 조립 지점.
        case pushEventReceived(PushEvent)
    }

    @Dependency(\.pushClient) var pushClient

    private enum CancelID { case pushStreams }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 푸시 스트림 구독 — 앱 세션 전체 수명. cold-start 알림 탭도 eager 버퍼로 도착한다.
                return .merge(
                    .run { send in
                        for await token in pushClient.fcmTokenUpdates() {
                            await send(.fcmTokenUpdated(token))
                        }
                    },
                    .run { send in
                        for await event in pushClient.events() {
                            await send(.pushEventReceived(event))
                        }
                    }
                )
                .cancellable(id: CancelID.pushStreams, cancelInFlight: true)
            case .auth(.delegate(.signedIn)):
                state.isAuthenticated = true
                // 알림 권한 요청 시점 = 로그인 직후. denied 후 재요청 UX 는 설정 화면 몫(후속).
                return .run { _ in
                    _ = try? await pushClient.requestAuthorization()
                }
            case .auth:
                return .none
            case .fcmTokenUpdated:
                // TODO: 백엔드 디바이스 토큰 등록 — 서버 스펙 확정 시 Domain 모듈(예: DomainNotification) 경유
                return .none
            case .pushEventReceived(.tapped):
                // 알림 탭 라우팅의 유일한 조립 지점 — 현재 탭이 home 뿐이라 홈 고정.
                // payload(data) 기반 딥링크 분기는 Feature 가 늘면 여기서 확장한다.
                state.selectedTab = .home
                return .none
            case .pushEventReceived:
                return .none
            case .home:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
