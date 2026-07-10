//
//  SocialLoginProvider.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import DomainAuthInterface

/// provider별 자격증명 획득 계약. 애플 로그인 추가 시 AppleLoginProvider가 이 protocol을 채택한다.
protocol SocialLoginProvider: Sendable {
    func performLogin() async throws -> SocialCredential
}
