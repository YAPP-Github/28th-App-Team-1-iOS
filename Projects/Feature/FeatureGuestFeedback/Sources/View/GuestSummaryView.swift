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
/// Figma 최종 «[4] 온보딩 - 메인(요약)»(node 2101:8781) 1:1 — 라이트 톤(흰 배경),
/// «평가 항목» 헤더 + «영상 다시보기» 버튼, 카드 탭 = 해당 축 수정(summaryCardTapped), 연필 아이콘.
/// 하단 블랙 `PrimaryButton`. `submitTapped` 은 라우터의 confirmationDialog(제출 불가역 경고)를 경유한다.
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
                    .padding(.vertical, .ds(.p20))
                }
                submitButton
            }
        }
    }

    // MARK: - 헤더 (타이틀 · 그린 마커 · 안내)

    /// "재원님에게" / "[이렇게 전달] 될 거예요" 2행(head3_b_24) + 수정 안내 부제 — Figma title-box(2101:8797).
    private var header: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(requesterName)님에게")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.Gray.g900)
                HStack(spacing: 0) {
                    // 그린 형광펜 마커 — 온보딩 "피드백" 과 동일한 사각형(dsBrandSoft).
                    Text("이렇게 전달")
                        .dsTypography(.head3)
                        .foregroundStyle(Color.Gray.g900)
                        .padding(.horizontal, .ds(.p8))
                        .background(Color.HilitGreen.g500, in: Parallelogram())
                    Text("될 거예요")
                        .dsTypography(.head3)
                        .foregroundStyle(Color.Gray.g900)
                }
            }
            Text("항목을 누르면 바로 수정할 수 있어요")
                .dsTypography(.body3)
                .foregroundStyle(Color.Gray.g500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var requesterName: String {
        store.entry?.requesterName ?? "지원자"
    }

    /// «평가 항목» 섹션 라벨 + 우측 «영상 다시보기» 미니 버튼(Figma button-mini/with-icon 2227:4448).
    private var sectionRow: some View {
        HStack(spacing: 0) {
            Text("평가 항목")
                .dsTypography(.body2)
                .foregroundStyle(Color.Gray.g900)
            Spacer(minLength: .ds(.p8))
            Button {
                send(.rewatchTapped)
            } label: {
                HStack(spacing: .ds(.p4)) {
                    // Figma 아이콘은 영상 재생 픽토그램 — 동일 의미의 SF 심볼로 대체.
                    Image(systemName: "play.rectangle.fill")
                        .font(.ds(.body8))
                    Text("영상 다시보기")
                        .dsTypography(.body5)
                }
                .foregroundStyle(Color.HilitBlack.b800)
                .padding(.horizontal, .ds(.p10))
                .padding(.vertical, .ds(.p8))
                // DS 에 radius 토큰이 없어 리터럴 유지(6pt).
                .background(Color.Gray.g100, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
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

    /// 카드 1개 — 축명 + 선택 라벨("(이)라고 평가했어요") + (코멘트 있으면) 코멘트 한 줄.
    /// 카드 전체가 버튼 — 탭하면 해당 축 수정으로 돌아간다(우상단 연필이 시각 힌트).
    private func summaryRow(_ axis: AttitudeAxis) -> some View {
        let rating = store.ratings[axis.code]
        return Button {
            send(.summaryCardTapped(axis))
        } label: {
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                Text(axis.displayName)
                    .dsTypography(.body9)
                    .foregroundStyle(Color.Gray.g400)

                HStack(spacing: .ds(.p4)) {
                    selectedLabel(for: axis, level: rating?.level)
                    Text("(이)라고 평가했어요")
                        .dsTypography(.body2)
                        .foregroundStyle(Color.Gray.g900)
                }

                if let comment = rating?.comment, !comment.isEmpty {
                    commentRow(comment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Figma 카드 padding px16 — 가로 16은 대응 spacing 토큰이 없어 리터럴 유지.
            .padding(.horizontal, 16)
            .padding(.vertical, .ds(.p14))
            .overlay(cardBorder)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "square.and.pencil")
                    .font(.ds(.body5))
                    .foregroundStyle(Color.Gray.g400)
                    .padding(.ds(.p12))
            }
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    /// 선택한 4단계 라벨 칩 — level 1·2 는 긍정(positive), 3·4 는 부정(error) 톤. 미선택은 "-" 중립.
    @ViewBuilder
    private func selectedLabel(for axis: AttitudeAxis, level: Int?) -> some View {
        if let level, (1...4).contains(level) {
            let isPositive = level <= 2
            labelChip(
                AxisScaleCopy.labels(for: axis.code)[level - 1],
                foreground: isPositive ? Color.Positive.p800 : Color.Error.e500,
                background: isPositive ? Color.Positive.p200 : Color.Error.e200
            )
        } else {
            labelChip("-", foreground: Color.Gray.g600, background: Color.Gray.g100)
        }
    }

    /// 평행사변형 배경 칩 — 라벨 텍스트(body3_m_16). Figma highlighted-text: 양옆 8pt(경사 4 + 평면 4).
    private func labelChip(_ text: String, foreground: Color, background: Color) -> some View {
        Text(text)
            .dsTypography(.body3)
            .foregroundStyle(foreground)
            .padding(.horizontal, .ds(.p8))
            .background(background, in: Parallelogram())
    }

    /// 코멘트 한 줄 — 세로 바 + 회색 텍스트(body9_m_12), 넘치면 말줄임.
    private func commentRow(_ comment: String) -> some View {
        HStack(spacing: .ds(.p4)) {
            Rectangle()
                .fill(Color.Gray.g100)
                // Figma 2px 세로 바 — 대응 두께 토큰 없어 리터럴 유지.
                .frame(width: 2)
            Text(comment)
                .dsTypography(.body9)
                .foregroundStyle(Color.Gray.g400)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// 카드 테두리 — gray100 스트로크(outline-m), 모서리 6pt(대응 radius 토큰 없어 리터럴).
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(Color.Gray.g100, lineWidth: .ds(.medium))
    }

    // MARK: - 하단 CTA

    private var submitButton: some View {
        PrimaryButton("피드백 전송하기", isLoading: store.isSubmitting) {
            send(.submitTapped)
        }
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
