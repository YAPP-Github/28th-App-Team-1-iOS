//
//  SegmentLedger.swift
//  DomainRecordingImplementation
//
//  Created by 서정원 on 26/08/08.
//

import DomainRecordingInterface
import Foundation

// @lat: [[interview#프리뷰]]
/// 세그먼트 원장(스펙 ①) — 백그라운드 경계마다 마감된 (비디오, 세션오디오) 쌍을 세션 단위로 쌓는다.
/// actor(CameraSessionManager) 가 소유해 세션 화면이 dismiss 돼도 프로세스가 살아 있는 한 유지된다.
/// 파일 IO 는 여기 없다 — 경로 계산·누적만(유닛 테스트 대상), 삭제·기록은 actor 몫.
struct SegmentLedger: Equatable {
    struct Segment: Equatable {
        let videoURL: URL
        let videoStartedAtHostSeconds: Double?
        let videoDurationSeconds: Double
        let audio: RecordingAudioSegment?
    }

    private(set) var sessionId: Int?
    private(set) var segments: [Segment] = []

    /// 지금까지 마감된 세그먼트 길이 합 — startRecording 반환값(시계 시드)·held 갱신의 재료.
    var cumulativeSeconds: Double { segments.reduce(0) { $0 + $1.videoDurationSeconds } }

    /// 새 세그먼트 시작 — 세션이 바뀌면 원장을 리셋한다(이전 세션 잔재가 새 세션에 섞이지 않게).
    /// 반환은 이 세그먼트가 기록할 파일 경로(세션·인덱스 네이밍).
    mutating func begin(sessionId: Int) -> URL {
        if self.sessionId != sessionId {
            self.sessionId = sessionId
            segments = []
        }
        return Self.videoURL(sessionId: sessionId, index: segments.count)
    }

    mutating func append(_ segment: Segment) {
        segments.append(segment)
    }

    mutating func reset() {
        sessionId = nil
        segments = []
    }

    static func videoURL(sessionId: Int, index: Int) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("interview-video-\(sessionId)-\(index).mp4")
    }

    /// 합성본 경로 — 세션당 하나(기존 네이밍 유지 — 업로드 큐 이관·정리 규칙이 이 이름을 안다).
    static func mergedURL(sessionId: Int) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("interview-recording-\(sessionId).mp4")
    }
}
