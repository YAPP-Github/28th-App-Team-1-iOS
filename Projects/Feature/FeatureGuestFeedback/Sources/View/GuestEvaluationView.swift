//
//  GuestEvaluationView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI

// @lat: [[feedback#G4 게스트 평가]]
/// G4 핵심 평가 화면 — 몰입/카드 두 모드를 오간다.
/// 최초 진입은 **몰입 모드**(시안 «영상 전체 보기»): 풀블리드 영상 + 하단 축 세그먼트만.
/// 축을 탭하면 **카드 모드**(Figma «[4] 객관식 - 선택 전/후» node 2150:7278·2192:4857):
/// 라운드 영상 카드 + 세그먼트 + 흰 카드(질문·극 라벨·4단계 칩·코멘트). 카드 영상의 ⛶ 가 몰입 복귀.
/// 코멘트는 흰 시트로 오버레이한다(«코멘트» 2101:8370).
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestEvaluationView: View {
    @Bindable var store: StoreOf<GuestFeedbackFeature>

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.dsBgDark.ignoresSafeArea()

            VStack(spacing: 0) {
                GuestVideoPlayerView(
                    videoURL: store.entry?.videoURL,
                    boundaries: store.entry?.questionBoundaries ?? [],
                    isImmersive: store.isImmersiveWatching,
                    onExpandTapped: { send(.expandVideoTapped) }
                )
                .padding(.horizontal, store.isImmersiveWatching ? 0 : .ds(.p20))
                .padding(.top, store.isImmersiveWatching ? 0 : .ds(.p8))
                // 몰입에선 상태바 뒤까지 풀블리드 — 카드 모드는 세이프에어리어 안에 머문다.
                .ignoresSafeArea(.container, edges: store.isImmersiveWatching ? .top : [])

                // 세그먼트 바는 자체 px20/py14 패딩 보유 — 다크 영상 배경 위에 얹힌다. 몰입에서 축 탭 = 카드 모드 진입(리듀서).
                // starting 동안엔 화면 밖(프로토타입 Flow 1: 카드 블록 top 812) — evaluating 전환 때 아래에서 슬라이드업.
                if store.phase != .starting {
                    AxisSegmentedBar(
                        axes: store.entry?.axes ?? [],
                        selected: store.activeAxis,
                        completedCodes: completedCodes,
                        onSelect: { send(.axisSelected($0)) }
                    )
                    .background(alignment: .bottom) {
                        if store.isImmersiveWatching {
                            immersiveBottomScrim
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !store.isImmersiveWatching {
                    whiteCard
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.ds(.white))
                    bottomCTA
                }
            }
            // 코멘트 시트가 뜰 때 키보드가 본문(영상·카드)을 밀어올리지 않도록 고정한다.
            .ignoresSafeArea(.keyboard, edges: .bottom)

            if store.commentEditing, store.activeAxis != nil {
                commentOverlay
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isImmersiveWatching)
        // Flow 1 전환(세그먼트 바 슬라이드업) — GuestFeedbackView 의 오버레이 페이드와 같은 커브로 동시 진행.
        .animation(.easeOut(duration: 0.35), value: store.phase)
    }

    /// 몰입 모드 하단 그라디언트 스크림 — Figma Rectangle 761489 실측(node 2148:4365, h 521):
    /// 위 투명 → 아래 블랙 선형 그라디언트 × fill-opacity 0.6 (그라디언트 종점이 rect 밖 749.5 라
    /// rect 하단 실효값 ≈ 블랙 42%). 세그먼트 바의 background 로 붙어 Flow 1 슬라이드업에 함께 참여하고,
    /// 로딩(starting) 중엔 시안대로 안 보인다(opacity 0 매칭 레이어). 시안의 bg blur 40 은 근사 생략.
    private var immersiveBottomScrim: some View {
        LinearGradient(
            colors: [Color.black.opacity(0), Color.black.opacity(0.42)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 521)
        .allowsHitTesting(false)
    }

    /// level 이 채워진 축 코드 집합 — 세그먼트 «완료» 표시(green 텍스트)를 구동한다.
    private var completedCodes: Set<String> {
        Set(store.ratings.filter { $0.value.level != nil }.map(\.key))
    }

    // MARK: - 하단 흰 카드 (질문 + 극 라벨 + 칩 + 코멘트)

    private var whiteCard: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            if store.entry?.submissionOpen == false {
                viewingOnlyBanner
            }
            if let axis = store.activeAxis {
                questionRow(axis)
                scaleBlock(axis)
                    .disabled(!store.canEvaluate)
                commentRow(axis)
                    .disabled(!store.canEvaluate)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .ds(.p20))
        .padding(.vertical, .ds(.p24))
    }

    /// 질문 헤드라인(sub4) + 우측 저장 인디케이터 (Figma tag-with-icon, node 2555:7558).
    /// 없음(미평가) → «저장 중 ...»(debounce 저장 진행) → «저장됨»(rating 존재) — savingAxisCode 로 구동.
    private func questionRow(_ axis: AttitudeAxis) -> some View {
        HStack(spacing: .ds(.p8)) {
            Text(AxisScaleCopy.headline(for: axis, requesterName: store.entry?.requesterName))
                .dsTypography(.sub4)
                .foregroundStyle(Color.ds(.black800))
            Spacer(minLength: .ds(.p8))
            saveIndicator(axis)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 저장 상태 표시 — 스피너+«저장 중 ...» / 그린 체크+«저장됨». 텍스트는 gray500 SemiBold12(.body8).
    @ViewBuilder
    private func saveIndicator(_ axis: AttitudeAxis) -> some View {
        if store.savingAxisCode == axis.code {
            HStack(spacing: .ds(.p4)) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.dsBrandSoft)
                indicatorLabel("저장 중 ...")
            }
        } else if store.ratings[axis.code]?.level != nil {
            HStack(spacing: .ds(.p4)) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.ds(.body2))   // 16pt 아이콘 — commentRow 의 plus(.body6) 와 같은 토큰 사이징 방식
                    .foregroundStyle(Color.dsBrandSoft)
                indicatorLabel("저장됨")
            }
        }
    }

    private func indicatorLabel(_ text: String) -> some View {
        Text(text)
            .dsTypography(.body8)
            .foregroundStyle(Color.ds(.gray500))
    }

    /// 극 라벨(좋았어요 ↔ 아쉬웠어요) + 4단계 칩 한 줄.
    private func scaleBlock(_ axis: AttitudeAxis) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            HStack(spacing: 0) {
                poleTag("좋았어요", background: Color.ds(.positive200), foreground: Color.ds(.positive800))
                Spacer()
                poleTag("아쉬웠어요", background: Color.ds(.error200), foreground: Color.dsError)
            }
            HStack(spacing: .ds(.p8)) {
                let labels = AxisScaleCopy.labels(for: axis.code)
                ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
                    AxisLevelChip(
                        label,
                        isSelected: store.ratings[axis.code]?.level == idx + 1,
                        tone: idx < 2 ? .positive : .negative
                    ) {
                        send(.levelSelected(idx + 1))
                    }
                }
            }
        }
    }

    /// Figma tag — px4, SemiBold12(.body8), 배경/텍스트 토큰만 다르다.
    private func poleTag(_ text: String, background: Color, foreground: Color) -> some View {
        Text(text)
            .dsTypography(.body8)
            .foregroundStyle(foreground)
            .padding(.horizontal, .ds(.p4))
            .background(background)
    }

    /// 접힌 코멘트 진입 행 — 점선 박스 + plus + "왜 그렇게 느꼈나요?" + "선택" 태그 (Figma button-optional).
    private func commentRow(_ axis: AttitudeAxis) -> some View {
        Button {
            send(.commentEditTapped)
        } label: {
            HStack(spacing: .ds(.p8)) {
                Image(systemName: "plus")
                    .font(.ds(.body6))
                    .foregroundStyle(Color.dsTextPrimary)
                Text("왜 그렇게 느꼈나요?")
                    .dsTypography(.body6)
                    .foregroundStyle(Color.dsTextPrimary)
                optionalTag
                Spacer(minLength: 0)
            }
            .padding(.ds(.p8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                // Figma button-optional(2227:4511) — 시안이 직사각형(radius 0) 점선 테두리.
                Rectangle()
                    .strokeBorder(
                        Color.dsSeparator,
                        style: StrokeStyle(lineWidth: .ds(.small), dash: [4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// "선택" 회색 태그 — gray100 배경 · gray600 텍스트(Figma tag).
    private var optionalTag: some View {
        Text("선택")
            .dsTypography(.body8)
            .foregroundStyle(Color.ds(.gray600))
            .padding(.horizontal, .ds(.p4))
            .background(Color.dsSeparator)
    }

    /// 시청 전용(FULL 정원 마감) 안내 — 흰 카드 위에 얹히는 라이트 톤 배너.
    private var viewingOnlyBanner: some View {
        HStack(spacing: .ds(.p8)) {
            Image(systemName: "person.3.fill")
                .foregroundStyle(Color.ds(.gray600))
            Text("이미 다른 지인이 참여했어요 — 영상만 볼 수 있어요")
                .dsTypography(.body6)
                .foregroundStyle(Color.ds(.gray600))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.ds(.p12))
        // DS 에 radius 토큰이 없어 리터럴 유지(8pt).
        .background(Color.dsSeparator, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 하단 CTA

    private var bottomCTA: some View {
        PrimaryButton("피드백 종료하기") {
            send(.reviewTapped)
        }
        .disabled(!store.isSubmitEnabled)
    }

    // MARK: - 코멘트 오버레이 (흰 시트)

    private var commentOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.ds(.black800).opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { send(.commentDismissed) }
            AxisCommentCard(
                text: $store.commentDraft,
                onDone: { send(.commentDoneTapped) },
                onDismiss: { send(.commentDismissed) }
            )
        }
    }
}

#Preview {
    var state = GuestFeedbackFeature.State(token: "preview")
    state.phase = .evaluating
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
        videoURL: nil,
        questionBoundaries: [],
        submissionOpen: true
    )
    state.activeAxis = state.entry?.axes.first
    // 시선=선택(미평가), 표정=완료(green 세그먼트) 시나리오.
    state.ratings = ["EXPRESSION": RatingDraft(level: 1, comment: "")]
    return GuestEvaluationView(
        store: Store(initialState: state) { GuestFeedbackFeature() }
    )
    .preferredColorScheme(.dark)
}
