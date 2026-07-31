//
//  GuestEvaluationView.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import SharedDesignSystemInterface
import SwiftUI
import UIKit

// @lat: [[feedback#G4 게스트 평가]]
/// G4 핵심 평가 화면 — 몰입/카드 두 모드를 오간다.
/// 최초 진입은 **몰입 모드**(시안 «영상 전체 보기»): 풀블리드 영상 + 하단 축 세그먼트만.
/// 축을 탭하면 **카드 모드**(Figma «[4] 객관식 - 선택 전/후» node 2150:7278·2192:4857):
/// 라운드 영상 카드 + 세그먼트 + 흰 카드(질문·극 라벨·4단계 칩·코멘트). 카드 영상의 ⛶ 가 몰입 복귀.
/// 코멘트는 흰 시트로 오버레이한다(«코멘트» 2101:8370).
@ViewAction(for: GuestFeedbackFeature.self)
struct GuestEvaluationView: View {
    @Bindable var store: StoreOf<GuestFeedbackFeature>

    /// 키보드 상단 y(글로벌) 실측 — 코멘트 아일랜드 도킹 기준. ∞ = 키보드 없음.
    /// 시스템 키보드 세이프에어리어는 한국어 후보 바(input accessory) 높이를 반영하지
    /// 못해 CTA 가 후보 바 뒤에 남는다 — willChangeFrame 의 endFrame 은 후보 바를 포함한다.
    @State private var keyboardTopY: CGFloat = .infinity

    var body: some View {
        // 코멘트 키보드는 닉네임 오버레이와 같은 2계층 위상으로 다룬다 — 배경+본문+토스트 계층을
        // **통째로** 키보드 무시로 고정하고, 코멘트 오버레이만 바깥 형제로 두어 키보드 회피에 참여시킨다.
        // 본문 VStack 에만 무시를 걸면 같은 ZStack 의 바닥 정렬이 본문이 확장한(키보드 뒤) 좌표계를
        // 기준 삼아 오버레이 CTA 가 키보드 뒤에 남는다.
        ZStack {
            ZStack(alignment: .bottom) {
                Color.HilitBlack.b800.ignoresSafeArea()

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
                            .background(Color.BlackWhite.white)
                        bottomCTA
                    }
                }

                if store.isCompletionToastVisible {
                    BubbleField("모든 평가가 끝났어요!")
                        // Figma 시안(node 2555:7543): CTA(55pt) 위 10pt — 55 는 ButtonLarge 고정 높이(대응 토큰 없어 리터럴).
                        .padding(.bottom, 55 + CGFloat.ds(.p10))
                        .transition(.opacity)
                }
            }
            // 코멘트 시트가 뜰 때 키보드가 본문(영상·카드·토스트)을 밀어올리지 않도록 계층째 고정한다.
            .ignoresSafeArea(.keyboard, edges: .bottom)

            if store.commentEditing, store.activeAxis != nil {
                commentOverlay
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isCompletionToastVisible)
        .animation(.easeInOut(duration: 0.25), value: store.isImmersiveWatching)
        // Flow 1 전환(세그먼트 바 슬라이드업) — GuestFeedbackView 의 오버레이 페이드와 같은 커브로 동시 진행.
        .animation(.easeOut(duration: 0.35), value: store.phase)
    }

    /// 몰입 모드 하단 그라디언트 스크림 — DS `VideoOverlay(.darkOpen)`(Figma «video overlay»
    /// dark/open 435:847, 375×523). 세그먼트 바의 background 로 붙어 Flow 1 슬라이드업에 함께
    /// 참여하고, 로딩(starting) 중엔 시안대로 안 보인다(opacity 0 매칭 레이어).
    /// 화면 전용 그라디언트(node 2148:4365 실측 521pt, 하단 실효 블랙 42%)를 걷어내고 DS 컴포넌트로
    /// 갈았다 — 램프가 시안 확정값(3스톱, 90.895% 에서 b900 도달)으로 바뀌어 하단이 더 진해진다.
    /// 시안의 bg blur 40 은 근사 생략(DS 컴포넌트도 반영하지 않는다).
    private var immersiveBottomScrim: some View {
        VideoOverlay(.darkOpen)
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
                // 시청 전용에선 «비활성»이 아니라 «읽기 전용»이다 — 이미 고른 값이 그대로 보여야 한다.
                // `.disabled` 를 쓰면 칩이 disabled 팔레트(g50/g300)로 수렴해 선택 표시가 사라진다.
                scaleBlock(axis)
                    .allowsHitTesting(store.canEvaluate)
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
                .foregroundStyle(Color.HilitBlack.b800)
            Spacer(minLength: .ds(.p8))
            saveIndicator(axis)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 저장 상태 표시 — DS `SaveIndicator`(저장 중/저장됨) 소비. 미평가는 아예 그리지 않는다.
    @ViewBuilder
    private func saveIndicator(_ axis: AttitudeAxis) -> some View {
        if store.savingAxisCode == axis.code {
            SaveIndicator(.saving)
        } else if store.ratings[axis.code]?.level != nil {
            SaveIndicator(.saved)
        }
    }

    /// 극 라벨(좋았어요 ↔ 아쉬웠어요) + 4단계 칩 한 줄.
    private func scaleBlock(_ axis: AttitudeAxis) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            HStack(spacing: 0) {
                TagLabel("좋았어요", foreground: Color.Positive.p800, background: Color.Positive.p200)
                Spacer()
                TagLabel("아쉬웠어요", foreground: Color.Error.e500, background: Color.Error.e200)
            }
            HStack(spacing: .ds(.p8)) {
                let labels = AxisScaleCopy.labels(for: axis.code)
                ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
                    ChoiceChip(
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

    /// 접힌 코멘트 행 — 코멘트가 없으면 점선 진입 버튼(Figma button-optional),
    /// 있으면 저장된 코멘트를 그린 액센트 바 + 한 줄 말줄임(…) + «수정» 링크로 보여준다.
    /// 어느 상태든 탭 = 코멘트 편집 진입.
    private func commentRow(_ axis: AttitudeAxis) -> some View {
        let comment = store.ratings[axis.code]?.comment ?? ""
        return Button {
            send(.commentEditTapped)
        } label: {
            if comment.isEmpty {
                emptyCommentLabel
            } else {
                filledCommentLabel(comment)
            }
        }
        .buttonStyle(.plain)
    }

    /// Figma «button-optional»(439:10206, 라벨 2227:4460) — padding-12 균일 · gap8 ·
    /// plus/16px/default · Medium14(body6) g900 라벨 · 회색 tag · outline-m 점선 테두리(g100, radius 0).
    private var emptyCommentLabel: some View {
        HStack(spacing: .ds(.p8)) {
            Image.Plus.default16
            Text("왜 그렇게 느꼈나요?")
                .dsTypography(.body6)
                .foregroundStyle(Color.GrayScale.g900)
            TagLabel("선택")
            Spacer(minLength: 0)
        }
        .padding(.ds(.p12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle()
                .strokeBorder(
                    Color.GrayScale.g100,
                    style: StrokeStyle(lineWidth: .ds(.medium), dash: [4])
                )
        )
    }

    /// 입력된 코멘트 표시 행 — 좌측 그린 액센트 바(4pt) · 한 줄 tail 말줄임 · 우측 «수정»(밑줄).
    /// 액센트 바는 HStack 자식이 아니라 overlay 로 얹는다 — Rectangle 을 자식으로 두면
    /// 세로 탐욕성 때문에 행이 카드의 남는 높이를 흡수해 빈 상태(점선 버튼)보다 커진다.
    private func filledCommentLabel(_ comment: String) -> some View {
        HStack(spacing: .ds(.p8)) {
            Text(comment)
                .dsTypography(.body6)
                .foregroundStyle(Color.GrayScale.g900)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: .ds(.p8))
            Text("수정")
                .dsTypography(.body8)
                .foregroundStyle(Color.GrayScale.g600)
                .underline()
        }
        .padding(.ds(.p8))                  // Figma quote-field/green2(435:1357) py8 — 나머지 값은 미대조(보고서 참조).
        .padding(.leading, .ds(.large))     // 액센트 바(4pt) 폭만큼 텍스트를 안쪽으로.
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle()
                .strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.medium))
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.HilitGreen.g500)
                .frame(width: .ds(.large))   // DSOutline.large = 4pt
        }
    }

    /// 시청 전용(FULL 정원 마감) 안내 — 흰 카드 위에 얹히는 라이트 톤 배너.
    private var viewingOnlyBanner: some View {
        HStack(spacing: .ds(.p8)) {
            Image(systemName: "person.3.fill")
                .foregroundStyle(Color.GrayScale.g600)
            Text("이미 다른 지인이 참여했어요 — 영상만 볼 수 있어요")
                .dsTypography(.body6)
                .foregroundStyle(Color.GrayScale.g600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.ds(.p12))
        // DS 에 radius 토큰이 없어 리터럴 유지(8pt).
        .background(Color.GrayScale.g100, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 하단 CTA

    private var bottomCTA: some View {
        ButtonLarge("피드백 종료하기", .bottom) {
            send(.reviewTapped)
        }
        .disabled(!store.isSubmitEnabled)
    }

    // MARK: - 코멘트 오버레이 (플로팅 아일랜드)

    /// 딤은 화면 전체(키보드 뒤까지) 고정, 카드+CTA 아일랜드만 키보드 위에 도킹한다.
    /// 도킹은 시스템 키보드 세이프에어리어가 아니라 **키보드 프레임 노티피케이션 실측**으로 민다 —
    /// 세이프에어리어 회피는 한국어 후보 바(input accessory)를 빼고 계산해 CTA 가 후보 바 뒤에
    /// 남는다(닉네임 패널의 "수동 계산 없음" 원칙의 예외 — 여기선 시스템 회피가 실측과 어긋난다).
    /// Figma «[4] 서술형»(2101:8370)의 묶음 노드 2227:5014 실측 — px20 / py14, 아일랜드 바닥 = 키보드 상단.
    private var commentOverlay: some View {
        GeometryReader { geo in
            ZStack {
                Color.HilitBlack.b800.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { send(.commentDismissed) }
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    AxisCommentCard(
                        text: $store.commentDraft,
                        onDone: { send(.commentDoneTapped) },
                        onDismiss: { send(.commentDismissed) }
                    )
                }
                .padding(.horizontal, .ds(.p20))
                .padding(.vertical, .ds(.p14))
                .padding(.bottom, keyboardOverlap(in: geo))
            }
        }
        // 시스템 회피를 끄고 실측만 쓴다 — 둘이 겹치면 이중 오프셋.
        .ignoresSafeArea(.keyboard)
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        ) { note in
            guard let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                .cgRectValue else { return }
            keyboardTopY = endFrame.minY
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            keyboardTopY = .infinity
        }
        .animation(.easeOut(duration: 0.25), value: keyboardTopY)
    }

    /// 아일랜드 기준 바닥(홈 인디케이터 위)과 키보드 상단(후보 바 포함)의 겹침 — 키보드 없으면 0.
    private func keyboardOverlap(in geo: GeometryProxy) -> CGFloat {
        max(0, geo.frame(in: .global).maxY - keyboardTopY)
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
        videoUrl: nil,
        questionBoundaries: [],
        submissionOpen: true
    )
    state.activeAxis = state.entry?.axisList.first
    // 시선=선택(미평가), 표정=완료(green 세그먼트) 시나리오.
    state.ratings = ["EXPRESSION": RatingDraft(level: 1, comment: "")]
    return GuestEvaluationView(
        store: Store(initialState: state) { GuestFeedbackFeature() }
    )
    .preferredColorScheme(.dark)
}
