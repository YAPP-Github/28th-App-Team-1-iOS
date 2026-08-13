//
//  GuestVideoPlaybackDisplayState.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/13.
//

import Foundation

/// 진행바 한 칸 = 질문 턴 하나. 서버가 주는 건 «시작 시각» 뿐이라 끝은 다음 칸의 시작(마지막은 영상 끝)이다.
struct GuestPlaybackChunk: Equatable, Identifiable, Sendable {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval

    var duration: TimeInterval { max(0, end - start) }

    /// 이 칸이 얼마나 채워졌는가(0~1). 재생 중인 칸만 부분 채움이고 지난 칸은 1, 앞 칸은 0 이다.
    func fillRatio(at time: TimeInterval) -> Double {
        guard duration > 0 else { return time >= start ? 1 : 0 }
        return min(1, max(0, (time - start) / duration))
    }
}

/// 재생 State 의 «무엇을 그릴지» 파생값 — 리듀서 파일과 나눠 둔다(리포트 플레이어와 같은 배치).
extension GuestVideoPlaybackFeature.State {
    /// 질문별 구간이 실제로 있는가 — 서버가 `questionBoundaries` 를 아직 안 준다(`docs/work/guest-feedback-question-boundaries.md`).
    /// 없으면 아래 «영상 전체 한 칸» 대체가 서고, 그 칸은 눌러도 이동하지 않는다.
    var hasQuestionSections: Bool { !boundaries.isEmpty }

    /// 진행바 칸. 질문 경계가 없으면 영상 전체를 한 칸으로 대체한다 — 바가 사라지지 않게.
    var progressChunks: [GuestPlaybackChunk] {
        let sorted = boundaries.sorted { $0.startAt < $1.startAt }
        guard !sorted.isEmpty else {
            return [GuestPlaybackChunk(id: 0, start: 0, end: max(duration, 1))]
        }
        let last = max(duration, sorted.last?.startAt ?? 0)
        return sorted.enumerated().map { index, boundary in
            let end = index + 1 < sorted.count ? sorted[index + 1].startAt : last
            return GuestPlaybackChunk(id: boundary.turnLevel, start: boundary.startAt, end: end)
        }
    }

    /// 끝까지 재생됐는지. 길이를 모르면(0) 판정하지 않는다.
    var hasReachedEnd: Bool { duration > 0 && currentTime >= duration }

    /// 재생할 영상이 붙어 있는가 — URL 이 없거나 열리지 않으면 placeholder 판이다.
    var hasPlayableVideo: Bool { videoURL != nil && playbackFailureMessage == nil }

    /// 가운데 재생 컨트롤 노출 조건 — 실패 안내가 화면을 차지하면 비운다.
    var isPlaybackControlVisible: Bool {
        areControlsVisible && hasPlayableVideo && isPrepared
    }

    /// 진행바 노출 조건 — **자동 숨김을 타지 않는다**(딤·재생 버튼만 3초 뒤 사라진다).
    var isProgressBarVisible: Bool { hasPlayableVideo && isPrepared }
}
