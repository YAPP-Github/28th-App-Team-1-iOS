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
// 흰 배경 · 좌상단 X 네비바 · 중앙(배지 54 + 타이틀/본문 + 이용권 안내) ·
// 하단 버튼은 kind 별 분기(STT «중단하기» 단일 / 네트워크 «이어서 진행하기»·«중단하기» 2분할 / 질문 준비 «처음으로»).
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
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            bottomButton
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        // 시안 «component/navigationbar»(X만) — 실패 화면은 스와이프 pop 이 리듀서 닫기 로직을 우회하므로 끈다.
        .hilitNavigationBar(allowsSwipeBack: false, onClose: { send(.userTappedClose) })
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

    /// 시안 «info-field» 인스턴스 — DS `InfoField(.gray)` 1:1. 좌우 여백 20 은 화면 몫.
    private var infoField: some View {
        InfoField(ticketNotice)
            .padding(.horizontal, .ds(.p20))
    }

    /// 시안: STT(2550:7504) «중단하기» 단일 · network(2638:17018) «이어서 진행하기»|«중단하기» 2분할(dark) ·
    /// 질문 준비는 시안 미출 — «처음으로» 임시 유지(PRD §3.2 재시도 없음).
    @ViewBuilder
    private var bottomButton: some View {
        switch store.kind {
        case .speechRecognition:
            ButtonLarge("중단하기", .bottom) { send(.userTappedAbort) }
        case .network:
            ButtonLarge(.bottom, tone: .dark) {
                Button("이어서 진행하기") { send(.userTappedResume) }
            } trailing: {
                Button("중단하기") { send(.userTappedAbort) }
            }
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
        case .speechRecognition: "마이크 상태를 확인하고 조용한 곳에서\n면접을 다시 시작해주세요."
        case .network: "네트워크가 불안정해 면접을 이어갈 수 없어요.\n연결을 확인하고 면접을 다시 시작해주세요."
        case .questionPrep: "면접 질문을 준비하지 못했어요.\n잠시 후 처음부터 다시 시도해주세요."
        }
    }

    /// 이용권 안내 — 시안 그대로: STT «면접을 중단해도 …» · network «중단하기를 선택할 경우에, …».
    private var ticketNotice: String {
        switch store.kind {
        case .speechRecognition: "면접을 중단해도 이용권은 차감되지 않아요"
        case .network: "중단하기를 선택할 경우에, 이용권은 차감되지 않아요"
        case .questionPrep: "이용권은 차감되지 않았어요"
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
