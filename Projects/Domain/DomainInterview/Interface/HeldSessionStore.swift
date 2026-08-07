//
//  HeldSessionStore.swift
//  DomainInterviewInterface
//
//  Created by EunseoKim on 26/08/08.
//

import ComposableArchitecture
import Foundation

// MARK: - 보관 값 (서버 스키마 아님 — 클라 로컬)

/// 진행 중(held) 면접 세션의 로컬 보관 값. 진행 중 세션 **목록 조회 API 가 없어**
/// 홈이 [이어서 진행] 에 실을 `sessionId` 를 클라가 들고 있어야 한다 ([[home#진입 로드]]).
public struct HeldSession: Codable, Equatable, Sendable {
    public var sessionId: Int
    /// 지금까지 녹화된 면접 영상 길이(초). 남은 질문 수 표기의 재료 — 최대 면접 길이 8분에서 뺀
    /// 잔여 시간으로 rule-base 환산하는 계산은 Feature 몫이고, 여기엔 저장만 한다.
    public var recordedSeconds: Int

    public init(sessionId: Int, recordedSeconds: Int) {
        self.sessionId = sessionId
        self.recordedSeconds = recordedSeconds
    }
}

// MARK: - Store

// 진행 중 세션의 로컬 영속 seam (UserDefaults, 외부 IO = Domain 레이어 규칙). 서버 무관이고
// 한 번에 한 세션만 보관한다 — 이용권 예약이 세션 하나를 잡는 구조라 동시 진행이 없다.
// 수명: 면접 세션 생성 시 저장(`recordedSeconds` 0) → 녹화 진행하며 갱신(면접 Feature 몫, 아직 미배선)
// → 면접 완료 시 삭제. 중단(abandon)·재개 불가(ENDED) 판정도 끝난 세션이라 같이 삭제한다.
public struct HeldSessionStore: Sendable {
    public var load: @Sendable () -> HeldSession?
    public var save: @Sendable (HeldSession) -> Void
    public var clear: @Sendable () -> Void

    public init(
        load: @escaping @Sendable () -> HeldSession?,
        save: @escaping @Sendable (HeldSession) -> Void,
        clear: @escaping @Sendable () -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

public extension HeldSessionStore {
    /// 인메모리 구현 — Preview·Example·Feature 테스트 용. UserDefaults 를 건드리지 않는다.
    static func inMemory(initial: HeldSession? = nil) -> HeldSessionStore {
        let held = LockIsolated<HeldSession?>(initial)
        return HeldSessionStore(
            load: { held.value },
            save: { session in held.withValue { $0 = session } },
            clear: { held.withValue { $0 = nil } }
        )
    }
}

extension HeldSessionStore: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지.
    public static var testValue: HeldSessionStore {
        HeldSessionStore(
            load: unimplemented("HeldSessionStore.load", placeholder: nil),
            save: unimplemented("HeldSessionStore.save"),
            clear: unimplemented("HeldSessionStore.clear")
        )
    }

    /// Preview 는 진행 중 세션이 **있는** 상태를 그린다 — 홈의 진행 중 변형이 그래야 보인다.
    public static var previewValue: HeldSessionStore {
        .inMemory(initial: HeldSession(sessionId: 1, recordedSeconds: 132))
    }
}

public extension DependencyValues {
    var heldSessionStore: HeldSessionStore {
        get { self[HeldSessionStore.self] }
        set { self[HeldSessionStore.self] = newValue }
    }
}
