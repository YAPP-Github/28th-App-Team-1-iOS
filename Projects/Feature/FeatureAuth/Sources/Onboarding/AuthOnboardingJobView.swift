//
//  AuthOnboardingJobView.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Onboarding_JobSelection» 초기 https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-14414
//                                  선택됨 https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-14437

import ComposableArchitecture
import DomainJobInterface
import SharedDesignSystemInterface
import SwiftUI

/// 가입 온보딩 2 — 직군 선택. 선택 상태는 칩 색(gray↔green)으로만 갈리고,
/// 하단 CTA 의 활성/비활성 룩은 DS(`ButtonLarge`)가 `isEnabled` 에서 파생한다.
@ViewAction(for: AuthOnboardingJobFeature.self)
public struct AuthOnboardingJobView: View {
    @Bindable public var store: StoreOf<AuthOnboardingJobFeature>

    public init(store: StoreOf<AuthOnboardingJobFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    titleBox
                    jobChips
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            continueButton
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(background: .filled, onClose: { send(.userTappedClose) })
        .onAppear { send(.onAppear) }
    }

    // MARK: - progress bar

    /// 시안 «progress bar» 3877:11580 — 단계 수만큼 등폭으로 늘어나는 대시. 여백 px20/py4 는 컴포넌트가 갖는다.
    private var progressBar: some View {
        DashIndicator(count: store.totalSteps, current: store.step)
            // 시안의 top-bar ↔ progress bar 간격 8 (네비바는 모디파이어가 얹는다)
            .padding(.top, .ds(.p8))
    }

    // MARK: - title-box

    private var titleBox: some View {
        TitleBox(
            [.init("\(store.userName)님의 직군을", highlight: "직군"), "선택해 주세요."],
            tag: "필수",
            sub: "\(store.userName)님의 현재 직군을 선택해 주세요."
        )
        .padding(.horizontal, .ds(.p20))
        .padding(.top, .ds(.p20))
    }

    // MARK: - 직무 칩

    private var jobChips: some View {
        Group {
            if store.jobs.isEmpty, store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ChipFlowLayout(spacing: .ds(.p8)) {
                    ForEach(store.jobs) { job in
                        jobChip(job)
                    }
                }
            }
        }
        .padding(.horizontal, .ds(.p20))
        // @ds(spacing): 34 — 칩 영역 위·아래 여백 (DSSpacing 은 24 까지)
        .padding(.vertical, 34)
    }

    /// 미선택 `.gray`(흰 판·g100 테두리·g700 글자) ↔ 선택 `.green`(g500 판·g600 테두리·g800 글자).
    /// 선택은 pressed·disabled 같은 «상태»가 아니라 시안이 색 축으로 표현하므로 색 파라미터로 넘긴다.
    private func jobChip(_ job: Job) -> some View {
        Button(job.label) {
            send(.userTappedJob(job.id))
        }
        .buttonStyle(.medium(store.selectedJobID == job.id ? .green : .gray))
    }

    // MARK: - 하단 CTA

    /// 단일 CTA — 뒤로는 스와이프백·내비바 X 몫. 비활성 룩(g50 판·g300 글자)은 DS 가 소유한다.
    private var continueButton: some View {
        ButtonLarge("다음", .bottom) { send(.userTappedContinue) }
            .disabled(!store.isContinueEnabled)
    }
}

// MARK: - ChipFlowLayout

/// 칩을 좌→우로 채우다 폭을 넘치면 줄바꿈하는 flow 레이아웃.
// @ds(layout): flow/wrap — 가변폭 칩 줄바꿈. DS 에 flow 컨테이너 없음(`ChoiceChip` 은 등폭 HStack 전용)
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

// MARK: - Previews

/// 시안(3632:14414)의 칩 순서 — 서버 응답 순서가 곧 표시 순서다.
private let previewJobs: [Job] = [
    Job(jobId: 1, jobRole: "BACKEND", label: "백엔드"),
    Job(jobId: 2, jobRole: "DATA_ENGINEER", label: "데이터 엔지니어"),
    Job(jobId: 3, jobRole: "ANDROID", label: "Android"),
    Job(jobId: 4, jobRole: "IOS", label: "iOS"),
    Job(jobId: 5, jobRole: "FRONTEND", label: "프론트엔드"),
    Job(jobId: 6, jobRole: "INFRA_SRE", label: "인프라 ⋅ SRE")
]

private func previewStore(selecting jobID: Job.ID? = nil) -> StoreOf<AuthOnboardingJobFeature> {
    var state = AuthOnboardingJobFeature.State(userName: "재원")
    state.jobs = previewJobs
    state.selectedJobID = jobID
    return Store(initialState: state) {
        AuthOnboardingJobFeature()
    } withDependencies: {
        $0.jobClient = JobClient(jobs: { previewJobs })
    }
}

#Preview("직군 선택 — 초기") {
    AuthOnboardingJobView(store: previewStore())
}

#Preview("직군 선택 — 선택됨") {
    AuthOnboardingJobView(store: previewStore(selecting: 4))
}
