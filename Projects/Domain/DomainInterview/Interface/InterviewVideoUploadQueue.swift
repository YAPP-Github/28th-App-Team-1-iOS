//
//  InterviewVideoUploadQueue.swift
//  DomainInterviewInterface
//
//  Created by 서정원 on 26/08/06.
//

import ComposableArchitecture
import Foundation

// @lat: [[interview#업로드 큐]]
/// 면접 영상 업로드 큐 — 화면·앱 수명과 무관하게 업로드를 완주시키는 유일한 통로(스펙 ⑤).
/// enqueue 가 파일 소유권을 가져가(영구 디렉토리 이동 + 저널 기록) 즉시 반환하고,
/// 실제 전송(발급 → background PUT → complete)은 큐가 뒤에서 진행한다. 진행·결과 UI 는 없다(조용한 업로드).
public struct InterviewVideoUploadQueue: Sendable {
    /// 산출물 접수 — 같은 sessionId 재접수는 무시(dedup). 반환 시점엔 파일 이동·저널 기록까지 끝나
    /// 있다(네트워크 미포함 — 코디네이터가 홈 전환 전에 await 해도 밀리초).
    public var enqueue: @Sendable (_ sessionId: Int, _ fileURL: URL, _ wrapUp: InterviewVideoWrapUpSpan?) async -> Void
    /// 미완 업로드 재개 — 앱 시작·background wake 에 1회. 만료(72시간) 항목 폐기도 여기서 한다.
    public var resumePending: @Sendable () async -> Void

    public init(
        enqueue: @escaping @Sendable (_ sessionId: Int, _ fileURL: URL, _ wrapUp: InterviewVideoWrapUpSpan?) async -> Void,
        resumePending: @escaping @Sendable () async -> Void
    ) {
        self.enqueue = enqueue
        self.resumePending = resumePending
    }
}

extension InterviewVideoUploadQueue: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: InterviewVideoUploadQueue {
        InterviewVideoUploadQueue(
            enqueue: unimplemented("InterviewVideoUploadQueue.enqueue"),
            resumePending: unimplemented("InterviewVideoUploadQueue.resumePending")
        )
    }

    /// Preview 용 — 업로드 없이 조용히 통과.
    public static var previewValue: InterviewVideoUploadQueue {
        InterviewVideoUploadQueue(enqueue: { _, _, _ in }, resumePending: {})
    }
}

public extension DependencyValues {
    var interviewVideoUploadQueue: InterviewVideoUploadQueue {
        get { self[InterviewVideoUploadQueue.self] }
        set { self[InterviewVideoUploadQueue.self] = newValue }
    }
}
