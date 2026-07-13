//
//  InterviewClientLive.swift
//  DomainInterviewImplementation
//
//  Created by EunseoKim on 26/07/07.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import Foundation

// @lat: [[interview#API]]
// depends-on: [[domain.map#네트워킹 인프라]] (NetworkClient 계약 — URLSession 등 구체는 모른다)
extension InterviewClient: DependencyKey {
    public static var liveValue: InterviewClient {
        @Dependency(\.networkClient) var networkClient
        return InterviewClient(
            fetchInterviews: {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try await networkClient.request(
                    NetworkRequest(path: "/interviews"),
                    as: [Interview].self,
                    decoder: decoder
                )
            }
        )
    }
}
