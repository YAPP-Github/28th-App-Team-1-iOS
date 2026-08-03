//
//  OnboardingJobSelectionView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/18.
//

import ComposableArchitecture
import DomainJobInterface
import SharedDesignSystemInterface
import SwiftUI

// Figma «STEP 1_직군선택» (node 1609:8484) 구현.
// 하단 바는 «Onboarding_JobSelection» (node 766:6564) 개정 — 단일 CTA → «이전으로 | 계속하기» 2분할.
// @ViewAction 매크로가 send(_:) 를 제공한다 — View 는 store.send(.view(...)) 대신 send(.onAppear) 로만 방출.
@ViewAction(for: OnboardingJobSelectionFeature.self)
public struct OnboardingJobSelectionView: View {
    @Bindable public var store: StoreOf<OnboardingJobSelectionFeature>

    public init(store: StoreOf<OnboardingJobSelectionFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DashIndicator(count: store.totalSteps, current: store.step)
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    header
                    jobChips
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
        .onAppear { send(.onAppear) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("필수")
                .dsTypography(.body7)
                .foregroundStyle(Color.HilitGreen.g500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.HilitBlack.b800, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("\(store.userName)님의 직군을\n선택해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("\(store.userName)님의 현재 직군을 선택해 주세요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    @ViewBuilder
    private var jobChips: some View {
        if store.isLoading, store.jobs.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else {
            ChipFlowLayout(spacing: 8) {
                ForEach(store.jobs) { job in
                    jobChip(job)
                }
            }
        }
    }

    private func jobChip(_ job: Job) -> some View {
        let isSelected = store.selectedJobID == job.id
        return Button {
            send(.userTappedJob(job.id))
        } label: {
            Text(job.label)
                .font(.ds(.body2))
                .foregroundStyle(Color.HilitBlack.b800)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.BlackWhite.white)
                .overlay {
                    // TODO: 선택 상태 Figma 미확인 — 우선 보더 강조. 디자인 확정 시 조정.
                    Rectangle()
                        .strokeBorder(isSelected ? Color.HilitBlack.b800 : Color.chipBorder, lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
    }

    /// 하단 «이전으로 | 계속하기» 바 — 나머지 스텝과 같은 2분할이다(시안 `2button-1disabled`).
    /// 배경·구분선·등폭 배치·눌림은 `ButtonLarge(.bottom, tone: .dark)` 가 소유하고,
    /// **직군을 고르기 전 비활성은 배색 변형이 아니라 상태**라 해당 자식에만 `.disabled` 를 건다.
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("이전으로") { send(.userTappedBack) }
        } trailing: {
            Button("계속하기") { send(.userTappedContinue) }
                .disabled(!store.isContinueEnabled)
        }
    }
}

// MARK: - ChipFlowLayout

/// 칩을 좌→우로 채우다 폭을 넘치면 줄바꿈하는 flow 레이아웃 (Figma 칩 배치 재현).
private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(fitting: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(fitting: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(fitting maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let appendedWidth = current.width + (current.indices.isEmpty ? 0 : spacing) + size.width
            if !current.indices.isEmpty, appendedWidth > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

private extension Color {
    /// 칩 기본 보더 · #EDEDED — Figma 변수 미바인딩 raw 값이라 DS 토큰화 보류.
    static let chipBorder = Color(red: 237 / 255, green: 237 / 255, blue: 237 / 255)
}

// MARK: - Previews

/// 칩 flow 레이아웃의 줄바꿈이 보이도록 previewValue 샘플(3개)보다 많은 6개를 쓴다.
private let previewJobs: [Job] = [
    Job(jobId: 1, jobRole: "BACKEND", label: "백엔드"),
    Job(jobId: 2, jobRole: "ANDROID", label: "Android"),
    Job(jobId: 3, jobRole: "IOS", label: "iOS"),
    Job(jobId: 4, jobRole: "FRONTEND", label: "프론트엔드"),
    Job(jobId: 5, jobRole: "DATA_ENGINEER", label: "데이터 엔지니어"),
    Job(jobId: 6, jobRole: "INFRA_SRE", label: "인프라 ⋅ SRE")
]

/// 선택 전 — [계속하기] 가 비활성이다(시안 `2button-1disabled`).
#Preview("직군 선택 — 선택 전") {
    OnboardingJobSelectionView(
        store: Store(initialState: OnboardingJobSelectionFeature.State(userName: "재원")) {
            OnboardingJobSelectionFeature()
        } withDependencies: {
            $0.jobClient = JobClient(jobs: { previewJobs })
        }
    )
}

/// 선택 후 — 두 버튼 다 활성. 선택은 draft 복원 경로(`preselectedJobRole`)로 흉내 낸다.
#Preview("직군 선택 — 선택됨") {
    OnboardingJobSelectionView(
        store: Store(
            initialState: OnboardingJobSelectionFeature.State(userName: "재원", preselectedJobRole: "IOS")
        ) {
            OnboardingJobSelectionFeature()
        } withDependencies: {
            $0.jobClient = JobClient(jobs: { previewJobs })
        }
    )
}
