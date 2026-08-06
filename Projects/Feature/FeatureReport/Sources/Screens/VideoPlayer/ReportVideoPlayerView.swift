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

// Figma «Report_VideoPlayer» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS
//   443:7804 기본(딤 없음) · 443:7852 컨트롤 노출(딤 65% + video-control) · 443:7902 대본 올림
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
            // 컨트롤을 띄우는 동안만 영상을 눌러 어둡게 한다.
            if store.isPlaybackControlVisible {
                // @ds(color): «hilit opacity/dark/65%» #000000 65% — 컨트롤 딤. 팔레트에 검정 토큰이 없다(BlackWhite 는 white 뿐)
                Color.black.opacity(Self.dimOpacity).ignoresSafeArea()
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
        // 영상 풀블리드 위 투명 바(기본값) — X 는 플레이어를 닫고 리포트로 (리듀서 소유).
        // 바닥이 어두운 영상이라 `surface: .dark`(흰 X). 시안은 `cancel/24px/dark`(검정 X)를
        // 얹었지만 DS 는 «다크 바닥 + 검정 X» 를 표현 불가로 못박았고, 딤 65% 위에선 안 보인다.
        .hilitNavigationBar(surface: .dark, onClose: { send(.userTappedBack) })
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
        // 재생 재시도 — 실패한 AVPlayer 는 되살아나지 않아 통째로 새로 만든다(플레이어는 뷰 소유).
        .onChange(of: store.reloadToken) { _, _ in
            tearDownPlayback()
            player = nil
            startPlayback()
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
        // 진입은 `startAt`, 재시도는 보고 있던 시각부터 — 둘 다 State 의 현재 시각이 답이다
        // (`currentTime` 초기값이 `startAt` 이고, 이후엔 재생 위치를 따라간다).
        if store.currentTime > 0 {
            player.seek(to: cmTime(store.currentTime))
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

    /// 상단 X 는 `.hilitNavigationBar` 가 얹는다 — 여기는 하단 바만 남는다.
    private var chrome: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            if store.isBottomBarVisible {
                bottomBar
            }
        }
    }

    /// Figma 443:7855 — 좌우 20, 진행바와 버튼 줄 사이 16, 버튼 줄은 오른쪽 정렬.
    /// 시안 버튼 줄 왼쪽에 빈 44×44 슬롯(443:7867)이 하나 더 있지만 내용이 없어 그리지 않는다.
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
    /// 대본을 켜면 같은 자리가 닫기 X 로 바뀐다 (Figma 443:7939 `cancel/20px/white`).
    // @ds(component): 44×44 g800 판(모서리 0) + 20pt 흰 글리프 — 아이콘 정사각 버튼 공용 컴포넌트 없음
    private var transcriptToggle: some View {
        Button {
            send(.userTappedTranscriptToggle)
        } label: {
            (store.isTranscriptVisible ? Image.Cancel.white20 : Image.Script.white20)
                .resizable()
                .scaledToFit()
                .frame(width: Self.toggleGlyphSize, height: Self.toggleGlyphSize)
                .frame(width: Self.controlSize, height: Self.controlSize)
                .background(Color.GrayScale.g800)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 재생 컨트롤

    /// Figma «video-control/play» 435:830 — 화살표 44 · 간격 46 · 가운데 74 정사각.
    /// 화살표는 초 단위가 아니라 진행바 한 칸씩 움직인다(이동 단위는 리듀서 소유).
    private var playbackControls: some View {
        HStack(spacing: Self.controlsSpacing) {
            chunkStepButton(Image.SkipL.white34) { send(.userTappedPreviousChunk) }
            playPauseButton
            chunkStepButton(Image.SkipR.white34) { send(.userTappedNextChunk) }
        }
    }

    private func chunkStepButton(_ icon: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: Self.glyphSize, height: Self.glyphSize)
                .frame(width: Self.controlSize, height: Self.controlSize)
        }
        .buttonStyle(.plain)
    }

    /// 연한 초록 정사각 판 + 짙은 초록 글리프 (Figma 435:833 — 모서리 0, p20).
    /// 시안엔 판 뒤 backdrop-blur 11.5 가 걸려 있지만 판이 불투명 g500 이라 보이지 않아 옮기지 않았다.
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

    /// 문구만 두면 막다른 화면이 된다(X 로 나가는 것 말고 할 게 없다) — 리포트 메인의
    /// «다시 시도하기» 와 같은 톤·같은 버튼으로 재생을 한 번 더 걸 길을 준다.
    private func failure(_ message: String) -> some View {
        VStack(spacing: .ds(.p12)) {
            Text(message)
                .dsTypography(.body3)
                .foregroundStyle(Color.GrayScale.g200)
                .multilineTextAlignment(.center)
            Button("다시 시도하기") { send(.userTappedPlaybackRetry) }
                .buttonStyle(.mini(.black))
        }
        .padding(.ds(.p20))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.HilitBlack.b900)
    }

    // MARK: - 수치 (Figma 스케일에 없는 컴포넌트 고유값은 여기 상수로 모은다)

    /// Figma 변수 «hilit opacity/dark/65%» — 딤 불투명도.
    private static let dimOpacity: Double = 0.65
    // @ds(layout): 44 — 컨트롤 버튼 한 변(화살표·대본 토글 슬롯). spacing 스케일(4~40)에 44 가 없다
    private static let controlSize: CGFloat = 44
    // @ds(icon): 34 — skip/pause/play 글리프. 에셋 원본 크기라 늘이지 않는다(image.md 크기 규칙)
    private static let glyphSize: CGFloat = 34
    // @ds(icon): 20 — script/cancel 글리프. 같은 이유로 에셋 원본 크기
    private static let toggleGlyphSize: CGFloat = 20
    // @ds(spacing): 46 — 화살표 ↔ 재생 버튼 간격(video-control gap). 스케일에 46 이 없다
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
                    reason: "PROBE_WORTHY",
                    title: "원인과 해결을 수치로 설명",
                    analysis: "문제를 바라보는 관점이 좋았어요.",
                    followUpQuestions: ["그 수치는 어떤 기간을 기준으로 집계한 건가요?"],
                    startSec: 2.3
                )
            ],
            resolutionNotice: nil,
            cardRedFlagNotices: nil,
            questionIntent: nil,
            scriptSegments: [
                ScriptSegment(
                    role: .interviewee,
                    text: "프로파일링하니 DB 왕복 7번이 원인이라,",
                    startIndex: 0,
                    endIndex: 22,
                    startSec: 0,
                    endSec: 2.3
                ),
                ScriptSegment(
                    role: .interviewee,
                    text: "안바뀌는 6번을 캐시로 흡수해 600ms 깎았어요.",
                    startIndex: 23,
                    endIndex: transcript.count,
                    startSec: 2.3,
                    endSec: 4.4
                )
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
