//
//  GuestFeedbackLocalStore.swift
//  DomainFeedbackInterface
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import Foundation

// @lat: [[feedback#임시저장과 Device-Id]]
// 게스트 로컬 상태(외부 IO = Domain 레이어 규칙). Device-Id 의 역할은
// 같은 기기의 중복 제출 방지 하나뿐이다 (PRD §2-5) — 그 이상을 얹지 않는다.
public struct GuestFeedbackLocalStore: Sendable {
    /// 기기 식별 값 — 최초 호출 시 UUID 생성 후 영속. 이후 항상 같은 값.
    public var deviceID: @Sendable () -> String
    /// 토큰별 임시저장 조회 ("다음에 하기" 이어하기).
    public var loadDraft: @Sendable (_ token: String) -> GuestFeedbackDraft?
    public var saveDraft: @Sendable (_ token: String, GuestFeedbackDraft) -> Void
    public var clearDraft: @Sendable (_ token: String) -> Void

    public init(
        deviceID: @escaping @Sendable () -> String,
        loadDraft: @escaping @Sendable (_ token: String) -> GuestFeedbackDraft?,
        saveDraft: @escaping @Sendable (_ token: String, GuestFeedbackDraft) -> Void,
        clearDraft: @escaping @Sendable (_ token: String) -> Void
    ) {
        self.deviceID = deviceID
        self.loadDraft = loadDraft
        self.saveDraft = saveDraft
        self.clearDraft = clearDraft
    }
}

public extension GuestFeedbackLocalStore {
    /// 인메모리 구현 — Preview·Example·Feature 테스트 용. UserDefaults 를 건드리지 않는다.
    static func inMemory(deviceID: String = "in-memory-device") -> GuestFeedbackLocalStore {
        let drafts = LockIsolated<[String: GuestFeedbackDraft]>([:])
        return GuestFeedbackLocalStore(
            deviceID: { deviceID },
            loadDraft: { drafts.value[$0] },
            saveDraft: { token, draft in drafts.withValue { $0[token] = draft } },
            clearDraft: { token in _ = drafts.withValue { $0.removeValue(forKey: token) } }
        )
    }
}

extension GuestFeedbackLocalStore: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지.
    public static var testValue: GuestFeedbackLocalStore {
        GuestFeedbackLocalStore(
            deviceID: unimplemented("GuestFeedbackLocalStore.deviceID", placeholder: "unimplemented"),
            loadDraft: unimplemented("GuestFeedbackLocalStore.loadDraft", placeholder: nil),
            saveDraft: unimplemented("GuestFeedbackLocalStore.saveDraft"),
            clearDraft: unimplemented("GuestFeedbackLocalStore.clearDraft")
        )
    }

    public static var previewValue: GuestFeedbackLocalStore { .inMemory() }
}

public extension DependencyValues {
    var guestFeedbackLocalStore: GuestFeedbackLocalStore {
        get { self[GuestFeedbackLocalStore.self] }
        set { self[GuestFeedbackLocalStore.self] = newValue }
    }
}
