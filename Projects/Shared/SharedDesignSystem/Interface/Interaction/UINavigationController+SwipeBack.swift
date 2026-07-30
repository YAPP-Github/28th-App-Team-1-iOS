//
//  UINavigationController+SwipeBack.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/07/30.
//

import SwiftUI
import UIKit

/// 엣지 스와이프백 정책 — 화면 단위 복구 + 차단.
///
/// `HilitNavigationBar` 모디파이어는 `navigationBarBackButtonHidden(true)` 를 걸어
/// 시스템 백버튼을 숨기는데, UIKit 은 «백버튼이 안 보이면» `interactivePopGestureRecognizer`
/// 를 스스로 꺼버린다(커스텀 내비 의도를 «pop 금지»로 확대 해석하는 오래된 안전장치).
/// 이 화면이 보이는 동안만 제스처 delegate 를 점유해 되살리고, 사라질 때 원래 delegate 로 되돌린다.
///
/// 왜 `UINavigationController` 전역 extension 이 아닌가: 기저 클래스 패치는
/// `UIImagePickerController`·`PHPickerViewController` 등 시스템 내비까지 delegate 를
/// 갈아치워 남의 제스처 처리를 오염시킨다(`fileImporter` 피커가 실제 경로).
/// 화면 부착형은 우리 스택에 우리 화면이 떠 있는 동안만 유효하다.
///
/// - `allows`: 이 화면에서 스와이프 pop 허용 여부. 스와이프는 버튼과 달리 화면의
///   «나가기 전 로직»(확인·제출)을 안 태우므로, pop 전에 되물을 게 있는 화면은 `false`.
///   상태에서 파생된 값이면(업로드 중 등) 뷰 업데이트마다 반영된다.
/// - `viewControllers.count > 1`: 루트에서 스와이프하면 화면이 먹통 되는 유명 버그 방지.
/// - `transitionCoordinator == nil`: push/pop 애니메이션 도중 스와이프 시작 글리치 방지.
/// - 스와이프 pop 은 리듀서에 `StackAction.popFrom(id:)` 로 도착한다 — `backRequested`
///   delegate 가 아니므로, back 경로에 로직을 넣을 땐 두 입구를 모두 살필 것.
struct SwipeBackPolicy: UIViewControllerRepresentable {
    let allows: Bool

    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.allows = allows
    }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var allows = true
        private weak var previousDelegate: UIGestureRecognizerDelegate?

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            previousDelegate = gesture.delegate
            gesture.delegate = self
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // 원래 주인에게 반환 — 시스템 화면·커스텀 바 없는 화면에 흔적을 남기지 않는다.
            navigationController?.interactivePopGestureRecognizer?.delegate = previousDelegate
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard allows, let navigationController else { return false }
            return navigationController.viewControllers.count > 1
                && navigationController.transitionCoordinator == nil
        }
    }
}
