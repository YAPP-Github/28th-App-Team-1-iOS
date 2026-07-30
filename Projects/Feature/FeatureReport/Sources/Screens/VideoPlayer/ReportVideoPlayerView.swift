//
//  ReportVideoPlayerView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import AVFoundation
import ComposableArchitecture
import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

// 영상 플레이어 — Figma «Report_VideoPlayer» (3033:14446 기본 · 2121:5998 대본 오버레이).
// 시스템 컨트롤을 쓰지 않고 AVPlayerLayer 를 직접 얹는다(Figma 컨트롤이 커스텀이라).
// AVPlayer 자체는 뷰 로컬이고, 재생 여부·시각은 리듀서가 소유한다 — 자세한 배경은 리듀서 주석.
@ViewAction(for: ReportVideoPlayerFeature.self)
public struct ReportVideoPlayerView: View {
    @Bindable public var store: StoreOf<ReportVideoPlayerFeature>
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?

    public init(store: StoreOf<ReportVideoPlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            // 영상·딤은 화면 끝까지 번지고, 상단 X·하단 바는 세이프에어리어를 지킨다.
            Color.HilitBlack.b900.ignoresSafeArea()
            videoSurface.ignoresSafeArea()
            // 컨트롤을 띄우는 동안만 영상을 눌러 어둡게 한다 (Figma «hilit opacity/dark/65%»).
            if store.isPlaybackControlVisible {
                Color.HilitBlack.b900.opacity(Self.dimOpacity).ignoresSafeArea()
            }
            if store.isTranscriptVisible {
                TranscriptOverlay(
                    lines: store.transcriptLines,
                    currentLineID: store.currentLineID,
                    onHighlightTap: { cardIndex, spanIndex in
                        send(.userTappedHighlight(cardIndex: cardIndex, spanIndex: spanIndex))
                    }
                )
            }
            if let message = store.playbackFailureMessage {
                failure(message)
            }
            if store.isPlaybackControlVisible {
                playbackControls
            }
            chrome
        }
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
        .onTapGesture { send(.userTappedSurface) }
        .onAppear {
            send(.onAppear)
            startPlayback()
        }
        .onDisappear(perform: tearDownPlayback)
        .onChange(of: store.isPlaying) { _, isPlaying in
            isPlaying ? player?.play() : player?.pause()
        }
        // 토큰만 본다 — 같은 시각으로 다시 이동해도(리플레이) 놓치지 않는다.
        .onChange(of: store.seekToken) { _, _ in
            player?.seek(to: cmTime(store.seekTarget), toleranceBefore: .zero, toleranceAfter: .zero)
        }
        .sheet(item: $store.scope(state: \.highlightDetail, action: \.highlightDetail)) { store in
            ReportHighlightDetailView(store: store)
        }
    }

    // MARK: - 영상

    @ViewBuilder
    private var videoSurface: some View {
        if let player {
            VideoSurface(player: player)
        }
    }

    private func startPlayback() {
        guard player == nil else {
            // 화면으로 되돌아온 경우 — 상태가 재생 중이면 뷰의 플레이어도 다시 돌린다
            // (`onDisappear` 에서 멈췄는데 `isPlaying` 은 그대로라 onChange 가 안 걸린다).
            if store.isPlaying { player?.play() }
            return
        }
        let player = AVPlayer(url: store.videoURL)
        if let startAt = store.startAt {
            player.seek(to: cmTime(startAt))
        }
        // 0.2초 간격 — 진행바 칸 채움과 대본의 «현재 줄» 이 따라올 만큼만 촘촘하게.
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.2, preferredTimescale: Self.timescale),
            queue: .main
        ) { time in
            // 재생 상황은 사용자 입력이 아니라 effect 결과라 inner 로 올린다 (D5).
            // 관찰은 0.2초마다 계속 오므로 «바뀐 것» 만 올린다.
            store.send(.inner(.timeUpdated(time.seconds)))

            if player.currentItem?.status == .failed {
                store.send(.inner(.playbackFailed(
                    message: ReportVideoPlayerFeature.playbackFailureMessage
                )))
                return
            }
            guard let duration = player.currentItem?.duration.seconds,
                  duration.isFinite, duration > 0
            else { return }
            if store.duration != duration {
                store.send(.inner(.durationLoaded(duration)))
            }
            if store.isPlaying, time.seconds >= duration {
                store.send(.inner(.playbackFinished))
            }
        }
        self.player = player
        player.play()
    }

    private func tearDownPlayback() {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        player?.pause()
    }

    private func cmTime(_ seconds: TimeInterval) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: Self.timescale)
    }

    // MARK: - 상단·하단 고정 요소

    private var chrome: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer(minLength: 0)
            if store.isBottomBarVisible {
                bottomBar
            }
        }
    }

    /// Figma 는 좌측 X 하나 — 플레이어를 닫으면 리포트로 돌아간다.
    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedBack)
            } label: {
                Image.Cancel.white24
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .ds(.p20))
        .frame(height: Self.navigationBarHeight)
    }

    private var bottomBar: some View {
        VStack(spacing: .ds(.p16)) {
            PlaybackProgressBar(store: store)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                transcriptToggle
            }
        }
        .padding(.horizontal, .ds(.p20))
        .padding(.bottom, .ds(.p12))
    }

    /// 아이콘만 있는 정사각 버튼은 DS 버튼 카탈로그(large/medium/mini/sub/tag)에 없는 티어라
    /// 여기서 만든다 — 플레이어 컨트롤 전용이고 두 번째 사용처가 없다(승격 규칙 ③ 미충족).
    private var transcriptToggle: some View {
        Button {
            send(.userTappedTranscriptToggle)
        } label: {
            (store.isTranscriptVisible ? Image.Cancel.white20 : Image.Script.white20)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: Self.controlSize, height: Self.controlSize)
                .background(Color.GrayScale.g800)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 재생 컨트롤

    private var playbackControls: some View {
        HStack(spacing: Self.controlsSpacing) {
            skipButton(Image.SkipL.white34) { send(.userTappedSkipBackward) }
            playPauseButton
            skipButton(Image.SkipR.white34) { send(.userTappedSkipForward) }
        }
    }

    private func skipButton(_ icon: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: Self.glyphSize, height: Self.glyphSize)
                .frame(width: Self.controlSize, height: Self.controlSize)
        }
        .buttonStyle(.plain)
    }

    private var playPauseButton: some View {
        Button {
            send(.userTappedPlayPause)
        } label: {
            // 원본색 에셋(그린 글리프) — 배경 그린과 짝이라 틴트하지 않는다.
            (store.isPlaying ? Image.Pause.green34 : Image.Play.green34)
                .resizable()
                .scaledToFit()
                .frame(width: Self.glyphSize, height: Self.glyphSize)
                .padding(.ds(.p20))
                .background(Color.HilitGreen.g500)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 재생 실패

    private func failure(_ message: String) -> some View {
        Text(message)
            .dsTypography(.body3)
            .foregroundStyle(Color.GrayScale.g200)
            .multilineTextAlignment(.center)
            .padding(.ds(.p20))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.HilitBlack.b900)
    }

    // MARK: - 수치 (Figma 스케일에 없는 컴포넌트 고유값은 여기 상수로 모은다)

    /// «hilit opacity/dark/65%».
    private static let dimOpacity: Double = 0.65
    private static let navigationBarHeight: CGFloat = 54
    /// 컨트롤 터치 영역 44 · 글리프 34 (Figma video-control).
    private static let controlSize: CGFloat = 44
    private static let glyphSize: CGFloat = 34
    private static let controlsSpacing: CGFloat = 46
    private static let timescale: CMTimeScale = 600
}

// MARK: - Preview

private extension InterviewReportCard {
    /// 프리뷰용 카드 — Sources 는 Testing 타겟에 의존하지 않아 여기서 최소 재료만 만든다.
    static var previewCard: InterviewReportCard {
        let transcript = "프로파일링하니 DB 왕복 7번이 원인이라, 안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요."
        return InterviewReportCard(
            axisOrder: 1,
            depthLevel: 1,
            questionText: "결제 응답 속도를 개선하신 경험을 말씀해주세요.",
            transcript: transcript,
            highlightSpans: [
                HighlightSpan(
                    startIndex: 9,
                    endIndex: transcript.count,
                    tone: "GOOD",
                    analysis: "문제를 바라보는 관점이 좋았어요.",
                    evidenceStartAt: 2.3
                )
            ],
            resolutionNotice: nil,
            cardRedFlagNotices: nil,
            questionIntent: nil,
            segments: [
                TranscriptSegment(text: "프로파일링하니 DB 왕복 7번이 원인이라,", start: 0, end: 2.3),
                TranscriptSegment(text: "안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요.", start: 2.3, end: 4.4)
            ]
        )
    }
}

#Preview("영상 플레이어 — 컨트롤") {
    ReportVideoPlayerView(
        store: Store(
            initialState: ReportVideoPlayerFeature.State(
                videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                cards: [.previewCard]
            )
        ) {
            ReportVideoPlayerFeature()
        }
    )
}

#Preview("영상 플레이어 — 대본 오버레이") {
    ReportVideoPlayerView(
        store: Store(
            initialState: {
                var state = ReportVideoPlayerFeature.State(
                    videoURL: URL(string: "https://example.com/interview/1.mp4")!,
                    cards: [.previewCard, .previewCard]
                )
                state.isTranscriptVisible = true
                state.duration = 4.4
                state.currentTime = 3
                return state
            }()
        ) {
            ReportVideoPlayerFeature()
        }
    )
}
