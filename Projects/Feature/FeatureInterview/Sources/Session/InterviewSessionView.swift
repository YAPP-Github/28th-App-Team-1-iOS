//
//  InterviewSessionView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

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
        // Figma ExitConfirm 딤: black 60%(.hilitModal 몫) + backdrop blur — 배경 콘텐츠를 블러해 근사한다.
        .blur(radius: presentedModal != nil ? 20 : 0)
        // 표출 페이드(0.2s easeInOut)는 .hilitModal 내장 애니메이션이 블러까지 함께 몬다.
        .hilitModal(item: presentedModal) { modal in
            switch modal {
            case .exitConfirm: exitConfirmModal
            case .earlyExitWarning: earlyExitWarningModal
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .animation(.easeInOut(duration: 0.3), value: store.toast)
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
            VStack(spacing: .ds(.p4)) {
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
        // 꼬리가 아래 «면접 종료하기» 버튼을 가리킨다 (Figma BubbleField status=bottom).
        BubbleField(toast.message, .wide(tail: toast.hasTail ? .bottom : .none))
    }

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
        .frame(minHeight: 34)
    }

    // MARK: - 종료 확인·이탈 경고 모달 (DS Modal + .hilitModal)

    /// 리듀서의 표출 Bool 2개를 뷰에서 enum 으로 접는다 — `.hilitModal(item:)` 규약(동시 표출 차단).
    private enum PresentedModal: Equatable {
        case exitConfirm
        case earlyExitWarning
    }

    private var presentedModal: PresentedModal? {
        if store.isExitConfirmPresented {
            .exitConfirm
        } else if store.isEarlyExitWarningPresented {
            .earlyExitWarning
        } else {
            nil
        }
    }

    /// 면접 종료 확인 — Figma «modal»(2555:7739) 1:1, 아이콘은 «finish/74px»(3951:210), 문구는 부록 C 확정.
    private var exitConfirmModal: some View {
        Modal(
            "면접을 마칠까요?",
            subText: "마치기를 클릭하는 즉시 면접이 종료됩니다.\n지금까지 답변으로 분석을 시작해요.",
            icon: Image.Img.finish
        ) {
            ButtonLarge(.modal, tone: .twoColor) {
                Button("계속하기") { send(.userTappedContinueInterview) }
            } trailing: {
                Button("마치기") { send(.userTappedFinishInterview) }
            }
        }
    }

    /// 8분 전 중도 이탈 경고 — Figma «modal»(3907:890): 아이콘 없음, «면접 계속하기»가 강조(검정) 쪽.
    /// 차감 사실만, 리포트 언급 금지 (PRD §3.7).
    private var earlyExitWarningModal: some View {
        Modal(
            "다음에 면접을 다시 진행할까요?",
            subText: "지금 나가면 방금 쓴 이용권 한장이 사라져요."
        ) {
            ButtonLarge(.modal, tone: .twoColor) {
                Button("그대로 나가기") { send(.userTappedLeaveInterview) }
            } trailing: {
                Button("면접 계속하기") { send(.userTappedContinueInterview) }
            }
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
