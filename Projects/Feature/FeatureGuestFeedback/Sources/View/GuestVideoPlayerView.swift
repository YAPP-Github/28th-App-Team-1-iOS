//
//  GuestVideoPlayerView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import AVFoundation
import ComposableArchitecture
import DomainGuestFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI

/// 평가 화면 영상 — 몰입(풀블리드)/카드 두 렌더를 가진다.
/// AVPlayer 는 뷰 로컬로 보유한다 — 몰입↔카드 전환에도 이 뷰가 구조상 같은 자리에 남아 재생이 끊기지 않는다.
/// 재생 여부·시각·컨트롤 표시는 리듀서(`GuestVideoPlaybackFeature`)가 갖고, 여기선 그 명령을 AVPlayer 에 옮긴다.
///
/// 컨트롤은 리포트 플레이어와 같은 규약이다: 영상 탭 → 딤 + `VideoControl` 노출 → 3초 뒤 자동 숨김,
/// 진행바는 붙박이(자동 숨김을 타지 않는다). 몰입에서만 딤·컨트롤·진행바를 얹는다 —
/// 카드 모드는 시안상 평가 카드가 화면 주인이라 영상 위에 판을 겹치지 않고, 이동은 아래 경계 칩이 맡는다.
@ViewAction(for: GuestVideoPlaybackFeature.self)
struct GuestVideoPlayerView: View {
    @Bindable var store: StoreOf<GuestVideoPlaybackFeature>
    /// 몰입 렌더(시안 진입 상태) — 카드 크롬(라운드·비율 고정·경계 칩·확대 버튼) 없이 가용 영역을 채운다.
    var isImmersive = false
    /// 지금 재생해도 되는가 — 시작 연출(블러 오버레이)이 걷히기 전엔 false 라 소리부터 새지 않는다.
    var isPlaybackAllowed = true
    /// 카드 모드 우하단 확대(⛶) 탭 — 평가 화면이 몰입 모드로 되돌린다.
    var onExpandTapped: () -> Void = {}

    @State private var player: AVPlayer?
    @State private var timeObserver: Any?

    // Figma «[4] 객관식»(node 2150:7278) 영상: 256×432 세로 프레임 — 다크 평가 화면 위 중앙 정렬.
    // DS 에 영상 치수 토큰이 없어 Figma 원값을 리터럴 상수로 보존한다.
    private let videoAspectRatio: CGFloat = 256.0 / 432.0
    private let videoMaxHeight: CGFloat = 432

    var body: some View {
        Group {
            if isImmersive {
                immersiveSurface
            } else {
                cardSurface
            }
        }
        .task(id: store.videoURL) { await prepare() }
        .onChange(of: isPlaybackAllowed) { _, allowed in
            if !allowed { player?.pause() } else if store.isPlaying { player?.play() }
        }
        .onChange(of: store.isPlaying) { _, isPlaying in
            guard isPlaybackAllowed else { return }
            if isPlaying { player?.play() } else { player?.pause() }
        }
        // 토큰만 본다 — 같은 시각으로 다시 이동해도(리플레이) 놓치지 않는다.
        .onChange(of: store.seekToken) { _, _ in
            player?.seek(to: cmTime(store.seekTarget), toleranceBefore: .zero, toleranceAfter: .zero)
        }
        // 재생 재시도 — 실패한 AVPlayer 는 되살아나지 않아 통째로 새로 만든다.
        .onChange(of: store.reloadToken) { _, _ in
            tearDownPlayback()
            player = nil
            Task { await prepare() }
        }
        .onDisappear(perform: tearDownPlayback)
    }

    // MARK: - 몰입 (풀블리드 + 컨트롤 계층)

    private var immersiveSurface: some View {
        ZStack {
            surface
            // 컨트롤을 띄우는 동안만 영상을 눌러 어둡게 한다. 컨트롤·진행바는 딤 위에 쌓아 색이 변하지 않게 한다.
            if store.isPlaybackControlVisible {
                // @ds(color): «hilit opacity/dark/65%» #000000 65% — 컨트롤 딤. 팔레트에 검정 토큰이 없다
                Color.black.opacity(Self.dimOpacity).ignoresSafeArea()
            }
            if let message = store.playbackFailureMessage {
                failure(message)
            }
            if store.isPlaybackControlVisible {
                playPausePlate
            }
            if store.isProgressBarVisible {
                progressBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { send(.userTappedSurface) }
    }

    /// 재생/일시정지 **하나만** 둔다 (사용자 결정 2026-08-13) — 지인 피드백엔 배속도, ±10초 건너뛰기도 없다.
    /// 그래서 DS `VideoControl`(좌우 스킵 화살표가 딸린 한 줄)을 쓰지 못하고 중앙 판만 여기서 만든다.
    /// 판 수치·글리프는 `VideoControl.playPausePlate` 와 동일하게 맞춘다 — 리포트 플레이어와 같은 물건으로 보이게.
    // @ds(component): 74 정사각 g500 판(모서리 0, 34 글리프 + p20) — «재생 버튼 하나» 변형이 DS 에 없다.
    // 두 번째 사용처가 생기면 VideoControl 의 변형으로 승격 대상(component.md 승격 규칙 ③).
    private var playPausePlate: some View {
        Button {
            send(.userTappedPlayPause)
        } label: {
            // 글리프는 «지금 상태»의 반대 동작을 그린다 — 재생 중이면 ⏸.
            (store.isPlaying ? Image.Pause.green34 : Image.Play.green34)
                .padding(.ds(.p20))
                .background(Color.HilitGreen.g500)
        }
        .buttonStyle(.plain)
    }

    /// 붙박이 진행바 — 밝은 영상 위에서도 읽히게 DS `VideoOverlay(.darkClose)` 램프를 깔고 그 위에 얹는다.
    private var progressBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            GuestPlaybackProgressBar(store: store)
                .padding(.horizontal, .ds(.p20))
                .padding(.bottom, .ds(.p12))
        }
        .background(alignment: .bottom) {
            VideoOverlay(.darkClose)
        }
    }

    // MARK: - 카드 (라운드 프레임 + 경계 칩 + 확대 버튼)

    private var cardSurface: some View {
        VStack(alignment: .leading, spacing: .ds(.p12)) {
            surface
                .aspectRatio(videoAspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottomTrailing) {
                    Button(action: onExpandTapped) {
                        // DS `Expand.default24` — g200 사각 타일 + 흰 화살표가 에셋에 구워져 있어
                        // 뒤에 별도 배경(thinMaterial 원)을 깔지 않는다(코너 0 판이라 원이 어긋난다).
                        Image.Expand.default24
                    }
                    .padding(.ds(.p8))
                }
                .frame(maxWidth: .infinity, maxHeight: videoMaxHeight)

            if player != nil, !store.boundaries.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .ds(.p8)) {
                        ForEach(store.boundaries, id: \.turnLevel) { boundary in
                            boundaryChip(boundary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 재생 표면

    @ViewBuilder
    private var surface: some View {
        if let player {
            // 몰입은 화면을 꽉 채우고, 카드는 세로 프레임 안에 온전히 담는다.
            GuestVideoSurface(player: player, gravity: isImmersive ? .resizeAspectFill : .resizeAspect)
                .background(Color.GrayScale.g900)
        } else {
            Color.GrayScale.g900
                .overlay { placeholderContent }
        }
    }

    /// 영상 미도착 자리 — **시안에 없는 코드 전용 상태**다(Figma 에 placeholder 변형이 없다).
    /// 아이콘만 DS 로 맞춘다: `Video.disabled24`(g200 글리프) — 다크 판 위 «아직 없음» 톤.
    private var placeholderContent: some View {
        VStack(spacing: .ds(.p8)) {
            Image.Video.disabled24
            Text("영상을 준비 중이에요")
                .dsTypography(.body7)
                .foregroundStyle(Color.GrayScale.g400)
        }
    }

    /// 재생 실패 — 문구만 두면 막다른 화면이 되므로 리포트 플레이어와 같은 톤으로 재시도를 준다.
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

    private func boundaryChip(_ boundary: QuestionBoundary) -> some View {
        Button {
            send(.userTappedChunk(index: boundary.turnLevel))
        } label: {
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                Text("Q\(boundary.turnLevel)")
                    .dsTypography(.body9)
                    .foregroundStyle(Color.BlackWhite.white)
                if let text = boundary.questionText {
                    Text(text)
                        .dsTypography(.body10)
                        .foregroundStyle(Color.GrayScale.g400)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, .ds(.p12))
            .padding(.vertical, .ds(.p8))
            // 다크 평가 배경 위 칩 — gray900 표면. DS 에 radius 토큰이 없어 리터럴 10pt 유지.
            .background(Color.GrayScale.g900, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 준비·재생

    /// `AVPlayer(url:)` 즉시 생성은 URL 이 살아 있는지 알려주지 않아, asset 을 먼저 열어보고 플레이어를 만든다.
    /// 열리지 않으면 플레이어를 만들지 않아 실패 안내가 남는다.
    ///
    /// **보고는 «이번에 준비를 시도한 결과» 일 때만 올린다** — 플레이어가 이미 살아 있으면 아무 말도 하지 않는다.
    /// 화면이 다시 나타나 `.task` 가 재실행될 때(이미 준비된 상태) 실패로 보고하면, 멀쩡히 재생 중인
    /// 영상에 실패 안내가 덮인다. 반대로 재시도(`reloadToken`)는 플레이어를 비우고 들어오므로 여기서 다시 보고한다.
    private func prepare() async {
        guard player == nil else { return }
        guard let videoURL = store.videoURL else {
            // URL 자체가 없는 경우(영상 파이프라인 전) — 실패가 아니라 «아직 없음» 이고, 판정은 리듀서가 한다.
            send(.videoPrepareFinished(isPlayable: false))
            return
        }

        let asset = AVURLAsset(url: videoURL)
        guard await isPlayable(asset) else {
            send(.videoPrepareFinished(isPlayable: false))
            return
        }

        activatePlaybackSession()
        startPlayback(with: asset)
        send(.videoPrepareFinished(isPlayable: true))
    }

    /// 플레이어를 만들고 0.2초 주기 관찰을 건다 — 진행바 칸 채움이 따라올 만큼만 촘촘하게.
    private func startPlayback(with asset: AVURLAsset) {
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        // 재시도는 보던 시각부터 — State 의 현재 시각이 답이다.
        if store.currentTime > 0 {
            player.seek(to: cmTime(store.currentTime))
        }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.2, preferredTimescale: Self.timescale),
            queue: .main
        ) { time in
            // 재생 상황은 사용자 입력이 아니라 effect 결과라 inner 로 올린다 (D5).
            store.send(.inner(.timeUpdated(time.seconds)))

            if player.currentItem?.status == .failed {
                store.send(.inner(.playbackFailed(
                    message: GuestVideoPlaybackFeature.playbackFailureMessage
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
        if isPlaybackAllowed, store.isPlaying { player.play() }
    }

    private func tearDownPlayback() {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        player?.pause()
    }

    /// 재생 가능 여부 판정 — 마감시한을 건 경주. 먼저 끝나는 쪽이 답이다.
    /// presigned URL 이 죽었을 때 AVFoundation 기본 타임아웃(60초)에 맡기면 시작 오버레이가 그만큼 남는다.
    private func isPlayable(_ asset: AVURLAsset) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { (try? await asset.load(.isPlayable)) ?? false }
            group.addTask {
                try? await Task.sleep(for: Self.prepareDeadline)
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    /// 무음 스위치가 켜져 있어도 면접 음성이 들려야 한다 — 태도 평가 항목에 목소리가 들어간다.
    /// 기본 카테고리(soloAmbient)는 무음 스위치를 따라 음소거된다. 게스트 플로우엔 녹음이 없어 .playback 으로 충분하다.
    private func activatePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    private func cmTime(_ seconds: TimeInterval) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: Self.timescale)
    }

    // MARK: - 수치

    /// Figma 변수 «hilit opacity/dark/65%» — 딤 불투명도(리포트 플레이어와 같은 값).
    private static let dimOpacity: Double = 0.65
    /// 준비 보고 마감시한.
    private static let prepareDeadline: Duration = .seconds(5)
    private static let timescale: CMTimeScale = 600
}
