//
//  SocialLoginProvider.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import DomainAuthInterface

/// provider별 자격증명 획득 계약. KakaoLoginProvider·AppleLoginProvider가 채택한다.
protocol SocialLoginProvider: Sendable {
    func performLogin() async throws -> SocialCredential
}
