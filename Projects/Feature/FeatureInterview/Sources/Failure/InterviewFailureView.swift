//
//  InterviewFailureView.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI

// Figma «[2] Interview_SttFailure»(2550:7504) · «[2] Interview_NetworkFailure»(2638:17018) 구현.
// 흰 배경 · 좌상단 X 내비바 · 중앙(배지 54 + 타이틀/본문 + 이용권 안내) · 하단 버튼은 kind 별 분기(STT 다시 시작하기 / 네트워크 홈으로 / 질문 준비 처음으로).
// 질문 준비 실패(Interview_QuestionPrepFailure)는 시안 미출 — 동일 레이아웃 임시.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.onAppear) 로만 방출.
@ViewAction(for: InterviewFailureFeature.self)
public struct InterviewFailureView: View {
    @Bindable public var store: StoreOf<InterviewFailureFeature>

    public init(store: StoreOf<InterviewFailureFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            bottomButton
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.default24
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, .ds(.p20))
        .frame(height: 54)
    }

    // MARK: - 중앙 콘텐츠 (배지 + title-box + info-field, gap 24)

    private var content: some View {
        VStack(spacing: .ds(.p24)) {
            failureBadge
            VStack(spacing: .ds(.p8)) {
                title
                Text(subtitle)
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, .ds(.p20))
            infoField
        }
    }

    /// Figma «mic error/54px»(2854:10975) · «network error/54px»(2854:10974) — 다크 타일·글리프·
    /// 빨간 느낌표 배지가 한 장에 구워진 일러스트라 DS 에셋을 그대로 얹는다.
    private var failureBadge: some View {
        switch store.kind {
        case .speechRecognition: Image.Img.micError
        // 질문 준비 실패 배지는 시안 미출 — network error 임시 재사용, 시안 확정 시 교체.
        case .network, .questionPrep: Image.Img.networkError
        }
    }

    /// 문장 전체를 넘기고 강조 구절만 지정한다 — 마커 밖 글자색은 `plainForeground`.
    private var title: some View {
        HighlightedText(
            highlightedWord + titleRemainder,
            typography: .head3,
            plainForeground: Color.HilitBlack.b800
        )
        .hilight(highlightedWord)
        .hilightColor(.red)
    }

    private var infoField: some View {
        HStack(spacing: .ds(.p8)) {
            Image.Info.default
            Text(ticketNotice)
                .dsTypography(.body9)
                .foregroundStyle(Color.GrayScale.g700)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, .ds(.p14))
        .padding(.vertical, .ds(.p12))
        .background(Color.GrayScale.g100)
        .padding(.horizontal, .ds(.p20))
    }

    /// PRD §3.9 STT = 재시작 유도 · §3.7 네트워크 = 홈으로만 · §3.2 질문 준비 = 처음으로만(재시도 없음).
    @ViewBuilder
    private var bottomButton: some View {
        switch store.kind {
        case .speechRecognition:
            ButtonLarge("다시 시작하기", .bottom) { send(.userTappedRestart) }
        case .network:
            ButtonLarge("홈으로", .bottom) { send(.userTappedClose) }
        case .questionPrep:
            ButtonLarge("처음으로", .bottom) { send(.userTappedClose) }
        }
    }

    // MARK: - 문구 (kind 별)

    private var highlightedWord: String {
        switch store.kind {
        case .speechRecognition: "목소리"
        case .network: "연결"
        case .questionPrep: "질문 준비"
        }
    }

    private var titleRemainder: String {
        switch store.kind {
        case .speechRecognition: "가 잘 들리지 않아요"
        case .network: "이 끊겼어요"
        case .questionPrep: "에 실패했어요"
        }
    }

    private var subtitle: String {
        switch store.kind {
        case .speechRecognition: "음성이 잘 인식되지 않아 면접을 이어갈 수 없어요.\n조용한 곳에서 면접을 다시 시작해주세요."
        case .network: "네트워크 연결이 끊겨 면접이 중단됐어요.\n연결 상태를 확인해주세요."
        case .questionPrep: "면접 질문을 준비하지 못했어요.\n잠시 후 처음부터 다시 시도해주세요."
        }
    }

    /// 이용권 안내 — 부록 C: 네트워크 «차감되지 않아요» · 질문 준비 «차감되지 않았어요» (STT 는 기존 유지).
    private var ticketNotice: String {
        switch store.kind {
        case .network: "이용권은 차감되지 않아요"
        case .speechRecognition, .questionPrep: "이용권은 차감되지 않았어요"
        }
    }
}

// MARK: - Previews

#Preview("STT 실패") {
    InterviewFailureView(
        store: Store(initialState: InterviewFailureFeature.State(kind: .speechRecognition)) {
            InterviewFailureFeature()
        }
    )
}

#Preview("네트워크 실패") {
    InterviewFailureView(
        store: Store(initialState: InterviewFailureFeature.State(kind: .network)) {
            InterviewFailureFeature()
        }
    )
}

#Preview("질문 준비 실패") {
    InterviewFailureView(
        store: Store(initialState: InterviewFailureFeature.State(kind: .questionPrep)) {
            InterviewFailureFeature()
        }
    )
}
