//
//  AuthClient+Live.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import ComposableArchitecture
import DomainAuthInterface
import Foundation

extension AuthClient: @retroactive DependencyKey {
    public static let liveValue = AuthClient(
        configure: { appKey in
            KakaoLoginProvider.configure(appKey: appKey)
        },
        handleOpenURL: { url in
            KakaoLoginProvider.handleOpenURL(url)
        },
        signIn: { provider in
            switch provider {
            case .kakao:
                return try await KakaoLoginProvider().performLogin()
            case .apple:
                return try await AppleLoginProvider().performLogin()
            }
        }
    )
}
