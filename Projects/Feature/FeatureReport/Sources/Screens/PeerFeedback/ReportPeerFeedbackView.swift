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

// Figma: «Report_PeerFeedback_RequestItems» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-8006
//        링크 생성 완료 팝업이 얹힌 판 443:8082 (모달 인스턴스 443:8121 = DS «modal» 2302:6080).
/// 지인에게 평가받을 태도 항목 선택 — 다크 판 위 «아이콘 + 이름 + 토글» 5줄과 하단 CTA 한 개.
/// CTA 를 누르면 링크가 만들어지고 그 자리에서 완료 팝업이 뜬다(링크 복사만 남는다).
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
                // @ds(layout): 51 — 머리글↔항목 목록 사이 (시안 절대 배치 217→268, spacing 스케일 밖)
                .padding(.top, 51)
            Spacer(minLength: 0)
            // 비활성(항목 0개)은 라이트용 g50 바로 그려진다 — 다크 화면용 disabled 변형이 시안에 없다.
            // @ds(component): 다크 판 CTA 비활성 — 시안 #27282F 판 + 흰 라벨(443:8046) → ButtonLarge
            // disabled(g50 판 + g300 라벨). 시트에 dark-disabled 칸이 없어 그대로 뒀다
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
                    // @ds(layout): 65 — 토스트를 CTA(높이 55) 위 10pt 에 놓는 값 (BubbleField 독스트링의 표준 배치)
                    .padding(.bottom, 65)
            }
        }
        // 링크 생성 완료 팝업 — 딤·중앙 배치·좌우 여백 24 는 DS 오버레이 몫(443:8082).
        // 스스로 닫지 않는다 — «링크 복사하기» 가 리듀서로 보낸 액션이 상태를 내린다.
        .hilitModal(isPresented: store.isCompletionModalVisible) {
            completionModal
        }
        // 복사 직후 시스템 공유 시트가 이어서 뜬다 — 붙여넣기와 바로 보내기 둘 다 지원.
        // 팝업(cover)이 닫힌 뒤에 올라온다 — 리듀서가 한 틱 벌려 둔다(`ReportPeerFeedbackFeature`).
        .sheet(isPresented: $store.isShareSheetPresented) {
            if let link = store.createdLink {
                ShareSheet(items: [Self.shareItem(link)])
                    .presentationDetents([.medium, .large])
            }
        }
        // X = 이 화면 나가기 — 리듀서가 소유(뒤로 신호를 delegate 로 올린다).
        .hilitNavigationBar(surface: .dark, onClose: { send(.userTappedBack) })
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
        // 시안은 네비바 아래(87)에서 머리글 첫 줄까지 20 — title-box 프레임 앞 10 + 프레임 안 pt10.
        .padding(.top, .ds(.p20))
    }

    /// 태도 항목 5줄 — 순서는 `AttitudeAxisKind.allCases`(시선·표정·자세·손동작·목소리) 고정.
    /// 줄 사이 `HilitDivider` 는 VStack 의 자식이라 위아래로 spacing 24 를 나눠 갖는다 (Figma 실측 pitch 76).
    private var axisList: some View {
        VStack(spacing: .ds(.p24)) {
            ForEach(Array(AttitudeAxisKind.allCases.enumerated()), id: \.offset) { index, axis in
                if index > 0 {
                    HilitDivider()
                }
                axisRow(axis)
            }
        }
        .padding(.horizontal, .ds(.p20))
    }

    /// 한 줄 — «28pt 아이콘 + 이름 + 오른쪽 끝 토글» (Figma 443:8053).
    private func axisRow(_ axis: AttitudeAxisKind) -> some View {
        HStack(spacing: .ds(.p8)) {
            // 시안이 `feedback/28px/*` 를 쓴다 — 크기마다 다시 그려진 에셋이라 20pt 판을 늘리지 않는다.
            GuestAttitudeCopy.icon28(for: axis)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text(GuestAttitudeCopy.name(for: axis))
                .dsTypography(.sub7)
                .foregroundStyle(Color.BlackWhite.white)
            Spacer(minLength: 0)
            // 라벨은 행 왼쪽에 이미 있으니 토글은 스위치만 — `HilitToggleStyle` 은 라벨을 넘기면
            // 스위치 왼쪽에 붙이고 `labelsHidden()` 이 듣지 않는다(커스텀 스타일 한계).
            Toggle(
                isOn: Binding(
                    get: { store.selectedAxes.contains(axis) },
                    set: { send(.userToggledAxis(axis, isOn: $0)) }
                )
            ) {
                EmptyView()
            }
            .toggleStyle(.hilit)
            .accessibilityLabel(GuestAttitudeCopy.name(for: axis))
        }
    }

    /// 링크 생성 완료 팝업의 **카드** — 링크 일러스트 74 + 두 줄 타이틀 + «링크 복사하기»(Figma 443:8121).
    /// 딤·폭·표출 전환은 `.hilitModal` 몫이라 여기서 그리지 않는다.
    private var completionModal: some View {
        Modal("링크 생성 완료!\n지인에게 보내보세요.", icon: Image.Img.link) {
            ButtonLarge("링크 복사하기", .modal) {
                send(.userTappedCopyLink)
            }
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
