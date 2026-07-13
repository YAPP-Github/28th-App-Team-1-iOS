//
//  SocialLoginProvider.swift
//  DomainAuthImplementation
//
//  Created by 서정원 on 26/07/10.
//

import DomainAuthInterface

protocol SocialLoginProvider: Sendable {
    func performLogin() async throws -> SocialCredential
}
