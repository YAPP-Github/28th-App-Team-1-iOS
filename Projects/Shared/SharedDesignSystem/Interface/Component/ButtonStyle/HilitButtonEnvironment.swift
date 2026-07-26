//
//  HilitButtonEnvironment.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/26.
//

import SwiftUI

/// 버튼이 놓인 판 — Figma 버튼 variant 의 `light/dark` 축.
///
/// 버튼 속성이 아니라 **화면 속성**이라 Environment 로 흐른다: 어두운 화면이면 그 안의 버튼이
/// 전부 dark 판을 쓰므로, 버튼마다 파라미터로 넘기면 반복이고 하나 빠뜨려도 티가 안 난다.
/// 화면 루트에서 `.hilitSurface(.dark)` 한 번이면 하위 버튼 스타일이 알아서 팔레트를 바꾼다.
public enum HilitSurface: Sendable {
    case light, dark
}

/// 버튼 로딩 상태 — 라벨을 숨기고 스피너를 얹는다.
///
/// `ButtonStyle` 은 라벨 내용을 갈아끼울 수 없어서(장식만 가능) 상태를 Environment 로 흘리고,
/// 스타일이 라벨을 `opacity(0)` 처리한 위에 스피너를 겹친다 — 라벨 크기가 유지돼 버튼 폭이 안 튄다.
public extension View {
    func hilitSurface(_ surface: HilitSurface) -> some View {
        environment(\.hilitSurface, surface)
    }

    /// 로딩 중인 버튼: 스피너 표시 + 탭 차단. 지원 스타일: `.largeBottom`.
    func hilitButtonLoading(_ isLoading: Bool) -> some View {
        environment(\.hilitButtonIsLoading, isLoading)
            .disabled(isLoading)
    }
}

extension EnvironmentValues {
    @Entry var hilitSurface: HilitSurface = .light
    @Entry var hilitButtonIsLoading: Bool = false
}
