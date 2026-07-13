//
//  SocialProvider.swift
//  DomainAuthInterface
//
//  Created by 서정원 on 26/07/13.
//

/// 소셜 로그인 제공자. 새 provider 추가 시 case만 늘어난다.
public enum SocialProvider: Equatable, Sendable {
    case kakao
    case apple
}
