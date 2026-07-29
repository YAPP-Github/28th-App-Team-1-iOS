//
//  InterviewSessionView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «[2] Interview_InProgress_Question»(2529:6309) · «…_Answering»(2537:9397 · 2638:1750) ·
// «…_ExitButtonShown»(2537:9442) · «…_FinalCountdown»(2537:9525) · «…_ExitConfirm»(2555:7696) 구현.
// 카메라 배경(하단 스크림만) 위에 상단 시간 칩 / 하단 상태 칩·토스트·미니 버튼을 얹고,
// 종료 확인은 딤+블러 오버레이 모달로 띄운다.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.onAppear) 로만 방출.
@ViewAction(for: InterviewSessionFeature.self)
public struct InterviewSessionView: View {
    @Bindable public var store: StoreOf<InterviewSessionFeature>

    public init(store: StoreOf<InterviewSessionFeature>) {
        self.store = store
    }

    // 카메라 backdrop 은 InterviewView(코디네이터 뷰) 상주 — 화면 교체 시 프리뷰 레이어 재생성 방지.
    // 모달 딤의 배경(카메라) 블러도 InterviewView 가 세션 상태를 읽어 함께 건다.
    public var body: some View {
        ZStack {
            CameraGuideFrame()

            VStack(spacing: 0) {
                timerChip
                    .padding(.top, 51)
                Spacer(minLength: 0)
                bottomBand
            }
        }
        .overlay(alignment: .topLeading) {
            // 이탈 동선 표기는 «협의 가능»(PRD §3.7) — 임시 X. 시안 확정 시 교체.
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.default24
            }
            .buttonStyle(.plain)
            .padding(.horizontal, .ds(.p20))
            .frame(height: 54)
        }
        // 카메라 위 다크 판 — 하위 `.mini` 버튼 팔레트가 이 선언을 따라 전환된다 (design/component.md).
        .hilitSurface(.dark)
        // Figma ExitConfirm 딤: black 60% + backdrop blur — 배경 콘텐츠를 블러해 근사한다.
        .blur(radius: (store.isExitConfirmPresented || store.isEarlyExitWarningPresented) ? 20 : 0)
        .overlay {
            if store.isExitConfirmPresented {
                exitConfirmOverlay
            } else if store.isEarlyExitWarningPresented {
                earlyExitWarningOverlay
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .animation(.easeInOut(duration: 0.3), value: store.toast)
        .animation(.easeInOut(duration: 0.2), value: store.isExitConfirmPresented)
        .animation(.easeInOut(duration: 0.2), value: store.isEarlyExitWarningPresented)
        .onAppear { send(.onAppear) }
    }

    // MARK: - 상단 시간 칩 (Figma top 94 = 상태바 43 + 51)

    private var timerChip: some View {
        InterviewTimerChip(
            variant: store.phase == .finalCountdown
                ? .countdown(remaining: store.countdownRemaining)
                : .elapsed(seconds: store.elapsedSeconds)
        )
    }

    // MARK: - 하단 밴드 (상태 칩·토스트 + 미니 버튼)

    /// Figma 하단 구성: 상태 칩(638)·안내 문구(669) ↔ 토스트(671)는 같은 밴드를 번갈아 쓰고,
    /// 미니 버튼 행(734)은 홈 인디케이터 위 10pt 에 붙는다. 토스트가 뜨면 상태 칩은 가린다.
    private var bottomBand: some View {
        VStack(spacing: 0) {
            if let toast = store.toast {
                toastView(toast)
            } else {
                statusArea
            }
            miniButtonRow
                .padding(.top, .ds(.p10))
                .padding(.bottom, .ds(.p10))
                .padding(.horizontal, .ds(.p20))
        }
    }

    @ViewBuilder
    private var statusArea: some View {
        switch store.phase {
        case .asking:
            VStack(spacing: 4) {
                HighlightedText("질문 듣는 중", typography: .body2)
                    .hilightColor(.green)
                Text("끝까지 듣고 대답해 주세요")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
            }
        case .answering:
            HighlightedText("답변 녹음 중", typography: .body2)
                .hilightColor(.black)
        case .processingAnswer:
            // 임시 — answering 칩과 동일 스타일. 상태 칩 시안 확정 시 교체 (PRD §3.5 «답변을 정리하고 있어요» 는 확정 문구).
            HighlightedText("답변을 정리하고 있어요", typography: .body2)
                .hilightColor(.black)
        case .finalCountdown:
            // 카운트다운 중 상태 칩 없음 — 상단 빨간 칩 + 상시 토스트만 (Figma 2537:9525).
            EmptyView()
        }
    }

    private func toastView(_ toast: InterviewSessionFeature.State.Toast) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            BubbleToast(toast.message)
            if toast.hasTail {
                // 꼬리가 아래 «면접 종료하기» 버튼을 가리킨다 (Figma BubbleField status=bottom).
                Image.Img.tooltipTail
            }
        }
    }

    /// «답변 완료하기»(답변 중) · «면접 종료하기»(8분 해금) — Figma 는 동시 노출 프레임이 없어
    /// 함께 뜰 땐 나란히 배치한다 (디자인 미정, 확인 필요).
    private var miniButtonRow: some View {
        HStack(spacing: .ds(.p8)) {
            Spacer(minLength: 0)
            if store.phase == .answering {
                Button("답변 완료하기") {
                    send(.userTappedAnswerComplete)
                }
                .buttonStyle(.mini(.green))
            }
            if store.isExitAvailable {
                Button("면접 종료하기") {
                    send(.userTappedExit)
                }
                .buttonStyle(.mini(.white))
            }
        }
        // 버튼이 없어도 행 높이를 유지해 상태 전환 시 하단 밴드가 튀지 않게 한다 (body5 18 + py8×2).
        .frame(minHeight: 34)
    }

    // MARK: - 종료 확인 (Figma 2555:7696)

    private var exitConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            InterviewExitConfirmModal(
                onContinue: { send(.userTappedContinueInterview) },
                onFinish: { send(.userTappedFinishInterview) }
            )
        }
    }

    /// 8분 전 중도 이탈 경고 (Interview_EarlyExitWarning) — 차감 사실만, 리포트 언급 금지 (PRD §3.7).
    private var earlyExitWarningOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            InterviewExitConfirmModal(
                title: "지금 나가면 이용권 1회가 차감돼요",
                message: nil,
                finishLabel: "나가기",
                onContinue: { send(.userTappedContinueInterview) },
                onFinish: { send(.userTappedLeaveInterview) }
            )
        }
    }
}

// MARK: - Previews

/// backdrop 은 실앱에선 InterviewView 상주 — 단독 프리뷰는 여기서 대신 깔아 화면 구도를 유지한다.
private func sessionPreview(
    _ mutate: (inout InterviewSessionFeature.State) -> Void = { _ in }
) -> some View {
    var state = InterviewSessionFeature.State()
    state.hasStarted = true   // onAppear 의 세션 시계를 막고 상태만 본다.
    mutate(&state)
    return ZStack {
        InterviewCameraBackdrop(showsTopScrim: false)
        InterviewSessionView(store: Store(initialState: state) { InterviewSessionFeature() })
    }
}

#Preview("질문 듣는 중") {
    sessionPreview { $0.elapsedSeconds = 1 }
}

#Preview("답변 녹음 중") {
    sessionPreview {
        $0.phase = .answering
        $0.elapsedSeconds = 80
    }
}

#Preview("답변 정리 중") {
    sessionPreview {
        $0.phase = .processingAnswer
        $0.elapsedSeconds = 82
    }
}

#Preview("8분 — 종료 해금") {
    sessionPreview {
        $0.phase = .answering
        $0.elapsedSeconds = 480
        $0.isExitAvailable = true
        $0.toast = .exitUnlocked
    }
}

#Preview("최종 카운트다운") {
    sessionPreview {
        $0.phase = .finalCountdown
        $0.elapsedSeconds = 710
        $0.isExitAvailable = true
        $0.toast = .timeExpired
    }
}

#Preview("종료 확인 모달") {
    sessionPreview {
        $0.phase = .answering
        $0.elapsedSeconds = 480
        $0.isExitAvailable = true
        $0.isExitConfirmPresented = true
    }
}

#Preview("중도 이탈 경고 — 8분 전") {
    sessionPreview {
        $0.phase = .answering
        $0.elapsedSeconds = 200
        $0.isEarlyExitWarningPresented = true
    }
}
