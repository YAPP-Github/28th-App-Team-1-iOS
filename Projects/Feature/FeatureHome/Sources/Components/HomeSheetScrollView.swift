//
//  HomeSheetScrollView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/08/07.
//

import SwiftUI
import UIKit

/// 리포트 목록 판 — **목록 스크롤과 시트 높이를 한 손짓으로 잇는** UIScrollView 브리지.
///
/// 라우팅 한 줄 요약: **시트가 갈 자리가 남았으면 시트가 먼저 먹고, 없으면 목록이 먹는다.**
/// - 위로 스와이프 + 시트가 확장 높이 아래 → 목록은 제자리, 시트가 손가락을 1:1 따라 올라간다.
/// - 확장 높이에 닿는 순간 → 남은 이동량부터 **같은 손짓 그대로** 목록 스크롤로 넘어간다.
/// - 아래로 스와이프 + 목록이 맨 위 → 스크롤 대신 시트가 내려온다(기본 자리에선 면접 시작까지).
///
/// SwiftUI `ScrollView` 로는 이동량을 가로챌 수 없어(`onScrollGeometryChange` 는 iOS 18+) 목록 통만
/// UIKit 으로 내리고, 행은 `UIHostingController` 로 기존 SwiftUI 뷰를 그대로 얹는다.
/// 자리·임계·착지 판정은 전부 `HomeSheetDrag` 소유다 — 여기가 새로 가진 건 «시트로 흘릴지 목록에
/// 넘길지» 라는 라우팅뿐이다.
struct HomeSheetScrollView<Content: View>: UIViewRepresentable {
    let dragHandle: HomeSheetDragHandle
    /// 확장 자리 여부 — 그 자리가 아닌데 목록이 스크롤된 채 남아 있으면 맨 위로 되돌린다.
    let isExpanded: Bool
    let content: Content

    init(
        dragHandle: HomeSheetDragHandle,
        isExpanded: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.dragHandle = dragHandle
        self.isExpanded = isExpanded
        self.content = content()
    }

    func makeCoordinator() -> HomeSheetScrollCoordinator {
        HomeSheetScrollCoordinator(dragHandle: dragHandle, content: AnyView(content))
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        // 행이 판보다 짧아도 손짓은 잡혀야 한다 — 안 그러면 짧은 목록에서 시트가 안 따라 올라온다.
        scrollView.alwaysBounceVertical = true
        // 안전영역 보정은 씬(`HomeView`)이 이미 했다 — 여기서 또 밀면 행 위아래에 빈 띠가 생긴다.
        scrollView.contentInsetAdjustmentBehavior = .never

        let hosted: UIView = context.coordinator.host.view
        hosted.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hosted)
        NSLayoutConstraint.activate([
            hosted.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosted.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosted.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // 가로는 판 너비에 못 박고 세로만 늘어나게 둬야 contentSize 가 행 높이 합으로 잡힌다.
            hosted.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.applyUpdate {
            // 통로는 프레임마다 새로 온다(클로저가 씬 상태를 문다) — 낡은 걸 들고 있으면 자리가 어긋난다.
            coordinator.dragHandle = dragHandle
            coordinator.host.rootView = AnyView(content)
            if !isExpanded {
                coordinator.resetOffsetIfNeeded(scrollView)
            }
        }
    }
}

/// 브리지의 손 — 스크롤 이동량을 시트 몫과 목록 몫으로 가르고, 손을 떼면 씬에 자리를 확정시킨다.
///
/// 이동량을 `contentOffset` 이 아니라 **팬 인식기**에서 읽는 이유: 목록이 경계에 붙어 있는 동안
/// 스크롤뷰는 고무줄로 값을 눌러 담아 1:1 이 아니다 — 그 값으로 시트를 밀면 손가락보다 느리게 올라온다.
/// 대신 인식기 이동량은 손가락 그대로라, 시트는 1:1 로 따라오고 목록 오프셋만 우리가 되돌려 준다.
///
/// 제네릭 클래스엔 `@objc` 멤버를 둘 수 없어(`UIScrollViewDelegate` 는 `@objc` 프로토콜) 콘텐츠 타입은
/// `AnyView` 로 지운다 — 행이 4개 안팎이라 비용이 없다.
@MainActor
final class HomeSheetScrollCoordinator: NSObject, UIScrollViewDelegate {
    /// 행 뷰를 그대로 얹는 호스트 — 높이는 `contentLayoutGuide` 핀 + 고유 크기로 잡는다.
    let host: UIHostingController<AnyView>
    /// 씬이 준 통로 — `updateUIView` 가 프레임마다 갈아끼운다.
    var dragHandle: HomeSheetDragHandle

    /// 손가락이 붙어 있는 동안만 true — 관성 구간은 목록에 그대로 맡긴다.
    private(set) var isTracking = false
    /// 이번 제스처에서 **시트가 먹은** 이동량(아래가 +). 목록에 넘긴 몫은 안 센다.
    private var travel: CGFloat = 0
    /// 직전 프레임까지 읽은 손가락 이동량 — 인식기 값은 제스처 시작 기준 누적이라 차분으로 쓴다.
    private var lastTranslation: CGFloat = 0
    /// 목록이 있어야 할 자리. 시트가 한 번이라도 이동량을 먹은 뒤부터는 스크롤뷰 대신 여기가 오프셋을
    /// 소유한다 — 그때부터 스크롤뷰 제 모델은 «시트가 먹은 만큼» 어긋나 있다.
    private var listOffset: CGFloat = 0
    /// 시트가 한 번이라도 움직였는지 — 순수 목록 스크롤이면 자리를 아예 건드리지 않는다.
    private var movedSheet = false
    /// 오프셋을 우리가 건드리는 동안(재진입)과 SwiftUI 갱신을 받는 동안(높이 변화로 뜨는 오프셋 보정)
    /// 라우팅을 멈추는 빗장. 갱신 중에 이동량으로 세면 «Modifying state during view update» 로 값이 튄다.
    private var isAdjusting = false

    init(dragHandle: HomeSheetDragHandle, content: AnyView) {
        self.dragHandle = dragHandle
        // super.init 전이라 self 를 못 읽는다 — 지역 변수로 세팅해 두고 마지막에 넘긴다.
        let host = UIHostingController(rootView: content)
        // 행 높이 합이 곧 contentSize 다 — 고유 크기를 켜야 내용이 바뀔 때 따라 갱신된다.
        host.sizingOptions = [.intrinsicContentSize]
        // 안전영역은 씬이 이미 처리했다 — 호스트가 또 밀면 행 위아래에 빈 띠가 생긴다.
        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        self.host = host
        super.init()
    }

    /// SwiftUI 갱신을 받는 동안 라우팅을 멈춘다(`isAdjusting`).
    func applyUpdate(_ body: () -> Void) {
        isAdjusting = true
        defer { isAdjusting = false }
        body()
    }

    /// 목록을 맨 위로 되돌린다 — 헤더 드래그로 확장 자리에서 내려온 뒤 남은 오프셋 정리용.
    /// 손이 붙어 있거나 관성이 도는 중이면 건드리지 않는다(그 둘은 이미 자기 목적지가 있다).
    func resetOffsetIfNeeded(_ scrollView: UIScrollView) {
        guard !isTracking, !scrollView.isDecelerating, scrollView.contentOffset.y != 0 else { return }
        listOffset = 0
        scrollView.setContentOffset(.zero, animated: false)
    }

    // MARK: - 이동량 라우팅

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isTracking = true
        travel = 0
        movedSheet = false
        lastTranslation = scrollView.panGestureRecognizer.translation(in: scrollView).y
        listOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isTracking, !isAdjusting else { return }
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView).y
        let delta = translation - lastTranslation
        lastTranslation = translation
        guard delta != 0 else { return }

        let toSheet = sheetShare(of: delta)
        if toSheet != 0 {
            travel += toSheet
            movedSheet = true
            dragHandle.onChanged(travel)
        }
        guard movedSheet else {
            // 시트가 한 번도 안 먹은 제스처는 스크롤뷰가 그대로 몰고 간다(고무줄·관성 전부 기본값).
            listOffset = scrollView.contentOffset.y
            return
        }
        listOffset = min(max(listOffset - (delta - toSheet), 0), maxOffset(of: scrollView))
        isAdjusting = true
        scrollView.contentOffset.y = listOffset
        isAdjusting = false
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard isTracking else { return }
        // 관성은 **손가락** 속도로 잰다 — 시트가 이동량을 먹는 동안 스크롤뷰 쪽 속도는 0 에 가깝다.
        let fingerVelocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        guard let settled = settle(velocity: fingerVelocity) else { return }
        // 시트가 관여한 제스처는 스크롤뷰 제 모델이 어긋나 있어 관성 목적지도 우리가 정한다.
        // 확장 자리로 앉을 때만 목록이 손짓을 이어 달리고, 다른 자리는 맨 위에 붙는다.
        let coasted = listOffset - HomeSheetDrag.projectedInertia(velocity: fingerVelocity)
        let target = settled == .expanded ? coasted : 0
        targetContentOffset.pointee.y = min(max(target, 0), maxOffset(of: scrollView))
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 보통은 willEndDragging 이 먼저 마감한다 — 제스처가 취소돼 그쪽이 안 불린 경우만 여기서 받는다.
        guard isTracking else { return }
        _ = settle(velocity: scrollView.panGestureRecognizer.velocity(in: scrollView).y)
    }

    // MARK: - 판정

    /// 이번 이동량 중 **시트가 먹을 몫**(아래가 +). 나머지는 목록이 먹는다.
    ///
    /// 위로는 확장 높이까지 남은 만큼, 아래로는 목록이 맨 위에 닿고 난 다음부터다 —
    /// 목록이 아직 위로 되감길 자리가 남았으면 그 몫은 목록이 먼저 가져간다.
    private func sheetShare(of delta: CGFloat) -> CGFloat {
        let range = dragHandle.travelRange
        if delta < 0 {
            return -min(-delta, max(travel - range.lowerBound, 0))
        }
        let afterList = delta - min(delta, max(listOffset, 0))
        return min(afterList, max(range.upperBound - travel, 0))
    }

    /// 손을 뗀 자리 확정 — 판정은 `HomeSheetDrag`, 반영은 씬이다.
    /// 시트가 한 번도 안 움직였으면 nil: 순수 목록 스크롤인데 자리를 건드리면 «임계 미달 → 기본 자리»
    /// 규칙에 걸려 멀쩡히 스크롤하던 확장 자리가 도로 내려앉는다.
    private func settle(velocity: CGFloat) -> HomeFeature.SheetDetent? {
        isTracking = false
        defer {
            travel = 0
            movedSheet = false
        }
        guard movedSheet else { return nil }
        let inertia = HomeSheetDrag.projectedInertia(velocity: velocity)
        return dragHandle.onEnded(HomeSheetDrag.settleTravel(actual: travel, inertia: inertia))
    }

    /// 목록이 내려갈 수 있는 최대 오프셋 — 내용이 판보다 짧으면 0 이다.
    private func maxOffset(of scrollView: UIScrollView) -> CGFloat {
        max(scrollView.contentSize.height - scrollView.bounds.height, 0)
    }
}
