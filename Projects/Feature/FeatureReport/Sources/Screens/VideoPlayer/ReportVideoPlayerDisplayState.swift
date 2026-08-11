//
//  ReportVideoPlayerDisplayState.swift
//  FeatureReport
//
//  Created by EunSeo on 26/08/07.
//

import ComposableArchitecture
import Foundation

/// 플레이어 State 의 «무엇을 그릴지» 파생값 — 리듀서 파일과 나눠 둔다(파일 길이 제한 400줄).
// 파생값은 모듈 안(View) 에서만 쓰고 `VideoTranscript` 를 노출하므로 internal 로 둔다.
extension ReportVideoPlayerFeature.State {
    /// 진행바 칸(= 질문 턴). 서버 발화가 없으면 영상 전체를 한 칸으로 대체한다 — 바가 사라지지 않게.
    /// 이 대체 칸은 `transcript.chunks` 에 없어서 탭해도 아무 일이 없다(이동할 구간을 모른다).
    var progressChunks: [VideoTranscript.Chunk] {
        guard transcript.chunks.isEmpty else { return transcript.chunks }
        return [VideoTranscript.Chunk(id: 0, start: 0, end: max(duration, 1))]
    }

    /// 지금 재생 위치가 걸린 진행바 칸. 첫 칸보다 앞이면 첫 칸으로 본다.
    var currentChunkIndex: Int? {
        let chunks = progressChunks
        guard !chunks.isEmpty else { return nil }
        return chunks.lastIndex(where: { $0.start <= currentTime }) ?? 0
    }

    /// 왼쪽 화살표가 갈 시각 — 한 칸 앞 칸의 시작. 첫 칸에서 누르면 그 칸을 다시 처음부터.
    var previousChunkStart: TimeInterval? {
        let chunks = progressChunks
        guard let index = currentChunkIndex else { return nil }
        return chunks[max(0, index - 1)].start
    }

    /// 오른쪽 화살표가 갈 시각 — 다음 칸의 시작. 마지막 칸에선 갈 곳이 없어 nil(탭 무반응).
    var nextChunkStart: TimeInterval? {
        let chunks = progressChunks
        guard let index = currentChunkIndex, chunks.indices.contains(index + 1) else { return nil }
        return chunks[index + 1].start
    }

    /// 오버레이가 보여줄 현재 턴 대본. 재생이 첫 발화 앞이면 nil — 그릴 문장이 없다.
    var activeTranscriptLine: VideoTranscript.Line? {
        guard let position = transcriptPosition else { return nil }
        return transcript.line(with: position.lineID)
    }

    /// 대본이 있는 보고서인가 — 서버 발화가 없으면 대본 토글 자체를 감춘다(눌러도 빈 판만 뜬다).
    var hasTranscript: Bool { !transcript.lines.isEmpty }

    /// 대본 오버레이 노출 조건 — 켠 상태 + **그릴 문장이 있을 때만**.
    /// 문장이 없는데 오버레이를 얹으면 글자 없는 스크림이 화면을 덮고, 오버레이가 소유한
    /// 하단 램프가 하단 스크림을 대신 못 해 하단 바 그라데이션이 어긋난다.
    var isTranscriptOverlayVisible: Bool { isTranscriptVisible && activeTranscriptLine != nil }

    /// 끝까지 재생됐는지. 길이를 모르면(0) 판정하지 않는다.
    var hasReachedEnd: Bool { duration > 0 && currentTime >= duration }

    /// 가운데 재생 컨트롤 노출 조건 — 대본이 떠 있으면 대본이 화면 주인이라 컨트롤은 비운다.
    var isPlaybackControlVisible: Bool {
        areControlsVisible
            && !isTranscriptOverlayVisible
            && playbackFailureMessage == nil
            && !isHighlightDetailPresented
    }

    /// 하단 바(진행바 + 대본 버튼 + 시트 진입 판의 «이전 화면으로 가기») 노출 조건 —
    /// **자동 숨김을 타지 않는다**: 진행바·대본 버튼은 화면의 붙박이고 딤·재생 버튼만 3초 뒤 사라진다.
    /// 재생 실패(안내가 화면을 차지)와 상세 시트(아래 사유)에서만 비운다.
    var isBottomBarVisible: Bool {
        playbackFailureMessage == nil && !isHighlightDetailPresented
    }

    /// 하단 스크림 노출 조건 — 붙박이 하단 바가 밝은 영상 위에서도 읽히게 한다(Figma 443:7830).
    /// 대본 오버레이가 **떠 있을 때만** 겹쳐 깔지 않는다(그때는 오버레이의 `.darkOpen` 램프가 대신한다) —
    /// 켜 뒀지만 그릴 문장이 없으면 램프도 없으니 하단 스크림이 그대로 남아야 한다.
    var isBottomScrimVisible: Bool { isBottomBarVisible && !isTranscriptOverlayVisible }

    /// 하단 «이전 화면으로 가기» 노출 조건 — 시트로 들어온 판에만 있다(돌아갈 시트가 있는 판).
    var isReturnToPreviousVisible: Bool { entry == .highlightSheet }

    /// 상단 X 노출 조건 — 시트를 보는 동안은 비운다.
    var isCloseButtonVisible: Bool { !isHighlightDetailPresented }

    /// 상세 시트가 올라와 있는 동안은 플레이어 컨트롤을 전부 비운다 (사용자 결정 2026-08-06).
    /// 시트는 화면을 다 덮지 않아 위쪽 띠에 X 가 남는데, 그 X 는 시트 밖이라 눌리고
    /// 눌리면 보던 하이라이트째로 플레이어를 떠난다 — 시트를 내리는 게 먼저다.
    private var isHighlightDetailPresented: Bool { highlightDetail != nil }
}
