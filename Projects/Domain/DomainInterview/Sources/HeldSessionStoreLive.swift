//
//  HeldSessionStoreLive.swift
//  DomainInterviewImplementation
//
//  Created by EunseoKim on 26/08/08.
//

import ComposableArchitecture
import DomainInterviewInterface
import Foundation

extension HeldSessionStore: @retroactive DependencyKey {
    /// 키에 버전을 박아 둔다 — 보관 값이 늘어 디코드가 깨지면 키를 올려 옛 값을 버린다.
    private static let key = "interview.heldSession.v1"

    public static var liveValue: HeldSessionStore {
        HeldSessionStore(
            load: {
                guard let raw = UserDefaults.standard.data(forKey: key),
                      let session = try? JSONDecoder().decode(HeldSession.self, from: raw)
                else { return nil }
                return session
            },
            save: { session in
                guard let raw = try? JSONEncoder().encode(session) else { return }
                UserDefaults.standard.set(raw, forKey: key)
            },
            clear: { UserDefaults.standard.removeObject(forKey: key) }
        )
    }
}
