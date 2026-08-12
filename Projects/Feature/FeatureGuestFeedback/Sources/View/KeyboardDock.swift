//
//  KeyboardDock.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/08/12.
//

import SwiftUI
import UIKit

// 오버레이를 키보드 위에 도킹하는 «시스템 회피 대신 실측» 패턴의 공용 부품.
//
// 시스템 키보드 세이프에어리어 회피만으로는 한국어 후보 바(input accessory) 높이가 빠져 CTA 가
// 후보 바 뒤에 남는다 — `willChangeFrame` 의 `endFrame` 은 후보 바를 포함한 최종 프레임이라
// 그 차이만큼을 이 부품이 메운다. 도킹이 필요한 오버레이가
// `.readsKeyboardTop(into:)` + `GeometryProxy.keyboardOverlap(below:)` 조합으로 쓴다.
//
// **배경이 키보드를 따라 올라가는 문제는 여기 소관이 아니다** — 그건 콘텐츠가 줄어든 컨테이너를
// 넘칠 때 SwiftUI 가 가운데 정렬하기 때문이고, `Color.clear` + `.overlay(alignment: .top)` 으로
// 넘침을 상단 정렬시켜 푼다(GuestFeedbackView.onboardingPhase 주석).

/// 키보드 상단 y(글로벌) 실측을 구독해 `topY` 로 흘려보낸다. `.infinity` = 키보드 없음.
///
/// `willChangeFrame` 의 `endFrame` 은 후보 바를 포함한 최종 프레임이라, 세이프에어리어가 놓치는
/// 높이까지 잡힌다.
struct KeyboardTopReader: ViewModifier {
    @Binding var topY: CGFloat

    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            ) { note in
                guard let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                    .cgRectValue else { return }
                topY = endFrame.minY
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                topY = .infinity
            }
    }
}

extension View {
    /// 키보드 상단 y(글로벌) 실측 구독 — 도킹 오버레이를 감싼 계층에 붙인다.
    func readsKeyboardTop(into topY: Binding<CGFloat>) -> some View {
        modifier(KeyboardTopReader(topY: topY))
    }
}

extension GeometryProxy {
    /// 이 영역의 바닥과 키보드 상단(후보 바 포함)의 겹침 — 키보드가 없으면 0.
    /// `.padding(.bottom,)` 으로 먹이면 오버레이 바닥이 키보드 상단에 정확히 붙는다.
    func keyboardOverlap(below keyboardTopY: CGFloat) -> CGFloat {
        max(0, frame(in: .global).maxY - keyboardTopY)
    }
}
