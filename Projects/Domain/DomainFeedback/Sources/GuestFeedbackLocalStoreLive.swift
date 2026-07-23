//
//  GuestFeedbackLocalStoreLive.swift
//  DomainFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainFeedbackInterface
import Foundation

// @lat: [[feedback#임시저장과 Device-Id]]
extension GuestFeedbackLocalStore: @retroactive DependencyKey {
    public static var liveValue: GuestFeedbackLocalStore { live(suiteName: nil) }

    /// suiteName 주입은 Tests 전용 — 매 호출 UserDefaults 를 새로 열어 Sendable 캡처 문제를 피한다.
    static func live(suiteName: String?) -> GuestFeedbackLocalStore {
        let defaults: @Sendable () -> UserDefaults = {
            suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        }
        return GuestFeedbackLocalStore(
            deviceID: {
                let store = defaults()
                if let existing = store.string(forKey: Keys.deviceID) {
                    return existing
                }
                let created = UUID().uuidString
                store.set(created, forKey: Keys.deviceID)
                return created
            },
            loadDraft: { token in
                guard let data = defaults().data(forKey: Keys.draft(token)) else { return nil }
                return try? JSONDecoder().decode(GuestFeedbackDraft.self, from: data)
            },
            saveDraft: { token, draft in
                guard let data = try? JSONEncoder().encode(draft) else { return }
                defaults().set(data, forKey: Keys.draft(token))
            },
            clearDraft: { token in
                defaults().removeObject(forKey: Keys.draft(token))
            }
        )
    }

    private enum Keys {
        static let deviceID = "guestFeedback.deviceID"
        static func draft(_ token: String) -> String { "guestFeedback.draft.\(token)" }
    }
}
