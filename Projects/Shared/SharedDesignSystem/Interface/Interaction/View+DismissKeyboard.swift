//
//  View+DismissKeyboard.swift
//  SharedDesignSystemInterface
//

import SwiftUI
import UIKit

public extension View {
    /// 키패드 밖 터치 시 키패드를 내린다 — 입력 필드가 있는 화면의 루트 컨테이너에 부착한다.
    /// 버튼·필드 등 인터랙티브 요소 탭은 그 요소가 우선 처리하므로 동작에 영향이 없다.
    func dismissesKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }
    }
}
