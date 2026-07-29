//
//  UINavigationController+SwipeBack.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/07/30.
//

import SwiftUI
import UIKit

/// 엣지 스와이프백 복구.
///
/// `HilitNavigationBar` 모디파이어는 `navigationBarBackButtonHidden(true)` 를 걸어
/// 시스템 백버튼을 숨기는데, UIKit 은 «백버튼이 안 보이면» `interactivePopGestureRecognizer`
/// 를 스스로 꺼버린다(커스텀 내비 의도를 «pop 금지»로 확대 해석하는 오래된 안전장치).
/// delegate 를 우리 것으로 교체해 판단을 단순화한다: 스택에 2장 이상 + 전환 중 아님이면 허용.
///
/// - `viewControllers.count > 1`: 루트에서 스와이프하면 화면이 먹통 되는 유명 버그 방지.
/// - `transitionCoordinator == nil`: push/pop 애니메이션 도중 스와이프 시작 글리치 방지.
/// - extension 의 `viewDidLoad` override 는 ObjC 런타임 디스패치로 동작하는 관용 트릭 —
///   Swift 공식 지원 밖이라 iOS 메이저 업데이트 때 스와이프백 동작을 한 번씩 확인할 것.
/// - **전역 적용**이다. 스와이프 pop 은 버튼과 달리 화면의 «나가기 전 로직»을 태우지 않으므로,
///   pop 전에 저장·확인이 필요한 화면은 그 로직을 pop 이후에도 안전하게 설계해야 한다.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1 && transitionCoordinator == nil
    }
}

/// 화면 단위 스와이프백 끄기 — 전역 복구의 반대 스위치.
///
/// 직접 쓰기보다 `.hilitNavigationBar(…, allowsSwipeBack: false)` 를 쓴다.
/// 화면이 보이는 동안만 `interactivePopGestureRecognizer` 를 끄고, 사라질 때 되돌린다 —
/// 같은 스택의 다른 화면에는 영향 없음.
struct SwipeBackDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
