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
    /// **면접이 시작된 프로세스**의 표식 — 세션 생성 시엔 nil 이고(아직 준비 단계), 세션 화면이
    /// 녹화를 열 때 찍힌다(2026-08-09). 앱이 죽으면 세그먼트 파일(tmp·프로세스 수명)이 사라져
    /// 재개가 불가능해지므로(스펙 ⑤), 다른 프로세스의 표식 = 정리 대상이다.
    public var processToken: UUID?

    /// 이 프로세스의 표식 — 실행마다 새 값. 저장 시 스탬프해 재실행 후 진행분 재개를 차단한다.
    public static let currentProcessToken = UUID()

    /// 홈이 [이어서 진행] 을 제안해도 되는가 — **표식이 없으면**(면접 전 준비 단계 보관분) 잃을 영상이
    /// 없어 프로세스를 넘어 재개 가능하고, 있으면 그게 이 프로세스일 때만이다. 어기면 앞부분 없는
    /// 영상에 마킹만 이어져 서버 정렬이 무너진다(스펙 ⑤).
    ///
    /// 판정을 «0초» 가 아니라 표식으로 하는 이유(2026-08-09 수정): `recordedSeconds` 는 백그라운드
    /// 마감에서만 갱신돼, 백그라운드를 거치지 않고 죽은 면접(크래시·메모리 압박)이 0초로 남는다.
    /// 0초를 무조건 재개 가능으로 보면 그 세션이 준비 이탈 보관분과 구분되지 않아 영영 정리되지 않는다.
    /// 표식 없는 구버전 저장값은 옛 규칙(0초 여부)으로 접는다 — 진행분이 있으면 죽은 값 취급.
    public var isResumableInCurrentProcess: Bool {
        guard let processToken else { return recordedSeconds == 0 }
        return processToken == Self.currentProcessToken
    }

    public init(sessionId: Int, recordedSeconds: Int, processToken: UUID? = nil) {
        self.sessionId = sessionId
        self.recordedSeconds = recordedSeconds
        self.processToken = processToken
    }
}

// MARK: - Store

// 진행 중 세션의 로컬 영속 seam (UserDefaults, 외부 IO = Domain 레이어 규칙). 서버 무관이고
// 한 번에 한 세션만 보관한다 — 이용권 예약이 세션 하나를 잡는 구조라 동시 진행이 없다.
// 수명: 면접 세션 생성 시 저장(`recordedSeconds` 0·표식 없음 = 준비 단계) → 세션 화면이 녹화를 열 때
// **프로세스 표식**을 찍고 → 백그라운드 마감(세그먼트 경계)마다 누적초로 갱신 → 면접 완료 시 삭제.
// 중단(abandon)·재개 불가(ENDED) 판정도 끝난 세션이라 같이 삭제한다.
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
    /// 프리뷰는 «살아 있는 프로세스의 진행분» 을 그린다 — 토큰을 안 찍으면 죽은 값이라 홈이 걸러 버린다.
    public static var previewValue: HeldSessionStore {
        .inMemory(
            initial: HeldSession(
                sessionId: 1,
                recordedSeconds: 132,
                processToken: HeldSession.currentProcessToken
            )
        )
    }
}

public extension DependencyValues {
    var heldSessionStore: HeldSessionStore {
        get { self[HeldSessionStore.self] }
        set { self[HeldSessionStore.self] = newValue }
    }
}
