//
//  ReportPeerFeedbackView.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import DomainInterviewReportInterface
import SharedDesignSystemInterface
import SwiftUI

/// 지인에게 평가받을 태도 항목 선택 — Figma «Report_PeerFeedback_RequestItems»(1964:727),
/// 링크 생성 완료 모달은 같은 화면의 3165:15392.
@ViewAction(for: ReportPeerFeedbackFeature.self)
public struct ReportPeerFeedbackView: View {
    @Bindable public var store: StoreOf<ReportPeerFeedbackFeature>

    public init(store: StoreOf<ReportPeerFeedbackFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            titleBox
            axisList
                // Figma 절대 배치(title-box 하단 217 → 목록 268) 실측치. spacing 스케일 밖의 레이아웃 값이다.
                .padding(.top, 51)
            Spacer(minLength: 0)
            // 비활성(항목 0개)은 라이트용 g50 바로 그려진다 — 다크 화면용 disabled 변형이 시안에 없다.
            // @ds(component): ButtonLarge dark-disabled 변형 없음 — 시안 나오면 교체
            ButtonLarge("피드백 링크 생성", .bottom) {
                send(.userTappedCreateLink)
            }
            .hilitButtonLoading(store.isCreating)
            .disabled(store.selectedAxes.isEmpty)
        }
        .background(Color.HilitBlack.b900.ignoresSafeArea())
        .hilitSurface(.dark)
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                BubbleField(toast)
                    // CTA(높이 55) 위 10pt — BubbleField 독스트링의 표준 배치.
                    .padding(.bottom, 65)
            }
        }
        .overlay {
            if store.isCompletionModalVisible {
                completionModal
            }
        }
        // 복사 직후 시스템 공유 시트가 이어서 뜬다 — 붙여넣기와 바로 보내기 둘 다 지원.
        .sheet(isPresented: $store.isShareSheetPresented) {
            if let link = store.createdLink {
                ShareSheet(items: [Self.shareItem(link)])
                    .presentationDetents([.medium, .large])
            }
        }
        // X = 이 화면 나가기 — 리듀서가 소유(뒤로 신호를 delegate 로 올린다).
        .hilitNavigationBar(theme: .dark, onClose: { send(.userTappedBack) })
        .onAppear { send(.onAppear) }
    }

    /// 공유 시트에는 URL 로 넘긴다 — 문자열보다 앱별 미리보기(카톡 링크 카드 등)가 살아난다.
    private static func shareItem(_ link: String) -> Any {
        URL(string: link) ?? link
    }

    /// 화면 머리글 — 글자색(다크 판 white/g300)·수직 리듬은 DS `TitleBox` 가 `.hilitSurface(.dark)` 에서 파생.
    private var titleBox: some View {
        TitleBox(
            ["지인에게 어떤 항목을", "평가받을까요?"],
            sub: "지인은 면접 태도를 중심으로 평가합니다.\n평가받고 싶은 항목을 선택해 주세요."
        )
        .padding(.horizontal, .ds(.p20))
        .padding(.top, .ds(.p10))
    }

    /// 태도 항목 5줄 — 순서는 `AttitudeAxisKind.allCases`(시선·표정·자세·손동작·목소리) 고정.
    /// 줄 사이 divider 는 VStack 의 자식이라 위아래로 spacing 24 를 나눠 갖는다 (Figma 실측 pitch 76).
    private var axisList: some View {
        VStack(spacing: .ds(.p24)) {
            ForEach(Array(AttitudeAxisKind.allCases.enumerated()), id: \.offset) { index, axis in
                if index > 0 {
                    Rectangle()
                        .fill(Color.GrayScale.g800)
                        .frame(height: .ds(.small))
                }
                axisRow(axis)
            }
        }
        .padding(.horizontal, .ds(.p20))
    }

    private func axisRow(_ axis: AttitudeAxisKind) -> some View {
        HStack(spacing: .ds(.p8)) {
            // 28px 변형 = 20px 에셋과 글리프 비율(71.4%)이 같아 gray900 배경 내장 에셋을 그대로 키운다.
            GuestAttitudeCopy.icon(for: axis)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text(GuestAttitudeCopy.name(for: axis))
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)
            Spacer(minLength: 0)
            // TODO: 디자인시스템 토글(Figma «toggle» 50×28 — 트랙 gray900 · 노브 gray50→green g500,
            // 모서리 0)이 머지되면 이 시스템 Toggle 을 교체한다. 지금은 크기(51×31)·모서리·트랙색이 다르다.
            Toggle(
                GuestAttitudeCopy.name(for: axis),
                isOn: Binding(
                    get: { store.selectedAxes.contains(axis) },
                    set: { send(.userToggledAxis(axis, isOn: $0)) }
                )
            )
            .labelsHidden()
            .tint(Color.HilitGreen.g500)
        }
    }

    /// 링크 생성 완료 모달 — 딤 65% + 폭 327 흰 카드 + 하단 «링크 복사하기»(Figma 3165:15492).
    /// 배경 탭으로는 닫히지 않는다. 링크는 이미 만들어졌고 복사만 남았다.
    /// 카드는 DS `Modal`(링크 배지 74 + 타이틀 + modal 버튼) — 딤은 호출부인 여기가 깐다.
    private var completionModal: some View {
        ZStack {
            Color.HilitBlack.b900.opacity(0.65)
                .ignoresSafeArea()

            Modal("링크 생성 완료!\n지인에게 보내보세요.", icon: Image.Img.link) {
                ButtonLarge("링크 복사하기", .modal) {
                    send(.userTappedCopyLink)
                }
            }
            .frame(width: 327)
        }
    }
}

// Preview 컨텍스트는 `previewValue` 를 자동으로 쓴다 — 링크 생성·복사 모두 주입 없이 돈다.
#Preview("항목 선택") {
    ReportPeerFeedbackView(
        store: Store(initialState: ReportPeerFeedbackFeature.State(sessionId: 1)) {
            ReportPeerFeedbackFeature()
        }
    )
}

#Preview("링크 생성 완료") {
    ReportPeerFeedbackView(
        store: Store(
            initialState: {
                var state = ReportPeerFeedbackFeature.State(sessionId: 1)
                state.selectedAxes = [.gaze, .voice]
                state.createdLink = "https://hilit.my/feedback/preview-token"
                state.isCompletionModalVisible = true
                return state
            }()
        ) {
            ReportPeerFeedbackFeature()
        }
    )
}
