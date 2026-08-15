//
//  GuestSummaryView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/22.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI

// @lat: [[feedback#G4 게스트 평가]]
/// 제출 전 요약 화면 — "재원님에게 이렇게 전달 될 거예요" 축별 평가 리스트 + 전송 CTA.
/// Figma 최종 «Peerfeedback_done»(node 802:7442) 1:1 — 라이트 톤(흰 배경),
/// «평가 항목» 헤더 + «영상 다시보기» 버튼, 카드 탭 = 해당 축 수정(summaryCardTapped), 연필 아이콘.
/// 하단 블랙 `ButtonLarge`(.bottom). `submitTapped` 은 DS Modal(제출 불가역 경고, `.hilitModal`)을 경유한다.
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestSummaryView: View {
    let store: StoreOf<GuestFeedbackFeature>

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.BlackWhite.white.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: .ds(.p20)) {
                        header
                        sectionRow
                        axisList
                    }
                    .padding(.horizontal, .ds(.p20))
                    // @ds(layout): 44 — 시안 top-bar(1947:6996) 높이. 그 아래 갭 16 자리에서 헤더가
                    // 시작한다(title-box y103 − 상태바 43 = 60). 닫기 X 는 흐름이 아니라
                    // 오버레이(GuestFeedbackView `closeButton`)라 이 화면이 바 높이만큼 자리를 비워 준다.
                    .padding(.top, 44 + CGFloat.ds(.p16))
                    .padding(.bottom, .ds(.p20))
                }
                submitButton
            }
        }
        .hilitModal(isPresented: store.isSubmitConfirmPresented) {
            submitConfirmModal
        }
    }

    /// 제출 불가역 확인 — 시스템 confirmationDialog 대신 DS `Modal` 2버튼(문구는 기존 다이얼로그 그대로).
    private var submitConfirmModal: some View {
        Modal(
            "제출하면 다시 고칠 수 없어요",
            subText: "제출 후에는 내용을 수정할 수 없어요."
        ) {
            ButtonLarge(.modal, tone: .twoColor) {
                Button("취소") { send(.submitConfirmDismissed) }
            } trailing: {
                Button("제출하기") { send(.submitConfirmTapped) }
            }
        }
    }

    // MARK: - 헤더 (타이틀 · 그린 마커 · 안내)

    /// DS TitleBox — Figma «title-box»(802:7447) 1:1: "{게스트}님, / 정성스러운 [피드백] 감사해요".
    /// 그린 마커는 둘째 줄 "피드백" 에만 — 시안에서 이름 줄은 highlighted-text 가 아닌 평문이다.
    private var header: some View {
        TitleBox(
            [
                TitleBox.Line("{\(guestName)}님,"),
                TitleBox.Line("정성스러운 피드백 감사해요", highlight: "피드백")
            ],
            sub: "\(requesterName)님에게 다음 피드백을 전달할게요"
        )
    }

    private var requesterName: String {
        store.entry?.requesterName ?? "지원자"
    }

    /// 타이틀의 게스트 이름 — 닉네임 확정 없이 요약에 오는 경로는 없지만, 빈 값이면 서버 자동 별칭 관례(지인N)를 따른다.
    private var guestName: String {
        store.nickname.isEmpty ? "지인" : store.nickname
    }

    /// «평가 항목» 섹션 라벨 + 우측 «영상 다시보기» 미니 버튼(Figma button-mini/with-icon 2227:4448).
    private var sectionRow: some View {
        HStack(spacing: 0) {
            Text("평가 항목")
                .dsTypography(.body2)
                .foregroundStyle(Color.GrayScale.g900)
            Spacer(minLength: .ds(.p8))
            Button {
                send(.rewatchTapped)
            } label: {
                // 아이콘은 16pt 로 그려진 에셋이라 리사이즈하지 않는다 (design/lessons.md 2번).
                HStack(spacing: .ds(.p8)) {
                    Image.Video.default16
                    Text("영상 다시보기")
                }
            }
            .buttonStyle(.mini(.gray, layout: .withIcon))
        }
    }

    // MARK: - 축별 요약 리스트

    private var axisList: some View {
        VStack(spacing: .ds(.p12)) {
            ForEach(store.entry?.axes ?? []) { axis in
                summaryRow(axis)
            }
        }
    }

    /// 카드 1개 — 축명 + 선택 라벨("(이)라고 평가했어요") + (코멘트 있으면) 인용 줄(DS QuoteField).
    /// 카드 전체가 버튼 — 탭하면 해당 축 수정으로 돌아간다(우상단 연필이 시각 힌트).
    /// Figma «feedback-card»(2102:9128) — 직각 판, g100 테두리(outline-m) + 왼쪽 outline-mega(6pt) 액센트.
    private func summaryRow(_ axis: AttitudeAxis) -> some View {
        let rating = store.ratings[axis.code]
        return Button {
            send(.summaryCardTapped(axis))
        } label: {
            // @ds(spacing): 6 — 카드 안 행 사이 (spacing 토큰은 4 다음이 8)
            VStack(alignment: .leading, spacing: 6) {
                Text(axis.displayName)
                    .dsTypography(.body9)
                    .foregroundStyle(Color.GrayScale.g400)

                HStack(spacing: 0) {
                    selectedLabel(for: axis, level: rating?.level)
                    Text("(이)라고 평가했어요")
                        .dsTypography(.body2)
                        .foregroundStyle(Color.HilitBlack.b800)
                }

                if let comment = rating?.comment, !comment.isEmpty {
                    QuoteField(comment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p16))
            .padding(.vertical, .ds(.p12))
            .overlay(
                Rectangle()
                    .strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.medium))
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.GrayScale.g100)
                    .frame(width: .ds(.mega))   // DSOutline.mega = 6pt 좌측 액센트 바
            }
            .overlay(alignment: .topTrailing) {
                // 시안 feedback-card(2102:9128) 우상단 «edit/16px/disabled» — 색은 에셋에 구워진 원본색.
                Image.Edit.disabled16
                    .padding(.top, .ds(.p12))
                    .padding(.trailing, .ds(.p16))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 선택한 4단계 라벨 칩 — level 1·2 는 긍정(blue 톤 + ⓘ청록), 3·4 는 부정(red 톤, 아이콘 없음). 미선택은 "-" 중립.
    @ViewBuilder
    private func selectedLabel(for axis: AttitudeAxis, level: Int?) -> some View {
        if let level, (1...4).contains(level) {
            let isPositive = level <= 2
            HighlightedText(AxisScaleCopy.labels(for: axis.code)[level - 1], typography: .body2)
                .hilightColor(isPositive ? .blue : .red)
                .hilightIcon(isPositive ? Image.Info.positive : nil)
        } else {
            HighlightedText("-", typography: .body2)
                .hilightColors(foreground: Color.GrayScale.g600, background: Color.GrayScale.g100)
        }
    }

    // MARK: - 하단 CTA

    private var submitButton: some View {
        ButtonLarge("피드백 전송하기", .bottom) {
            send(.submitTapped)
        }
        .hilitButtonLoading(store.isSubmitting)
        .disabled(!store.isSubmitEnabled)
    }
}

#Preview {
    var state = GuestFeedbackFeature.State(token: "preview")
    state.phase = .summary
    state.entry = GuestFeedbackEntry(
        gate: .open,
        requesterName: "재원",
        axes: [
            AttitudeAxis(code: "GAZE", displayName: "시선"),
            AttitudeAxis(code: "EXPRESSION", displayName: "표정"),
            AttitudeAxis(code: "POSTURE", displayName: "자세"),
            AttitudeAxis(code: "GESTURE", displayName: "손동작"),
            AttitudeAxis(code: "VOICE", displayName: "목소리")
        ],
        videoUrl: nil,
        questionBoundaries: [],
        submissionOpen: true
    )
    state.ratings = [
        "GAZE": RatingDraft(level: 1, comment: "시선이 안정적이고 듣는 사람이 편안해지는 시선처리가 인상적입니다"),
        "EXPRESSION": RatingDraft(level: 3, comment: "조금 더 안정적으로 표정 처리를 해주세요"),
        "POSTURE": RatingDraft(level: 2, comment: ""),
        "GESTURE": RatingDraft(level: 4, comment: ""),
        "VOICE": RatingDraft(level: 1, comment: "조금 더 큰 소리로 말해도 될 거 같아요")
    ]
    return GuestSummaryView(
        store: Store(initialState: state) { GuestFeedbackFeature() }
    )
}
