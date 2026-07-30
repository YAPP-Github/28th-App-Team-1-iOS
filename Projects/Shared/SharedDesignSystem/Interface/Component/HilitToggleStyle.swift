//
//  HilitToggleStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

// Figma: «Toggle» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2044-4999
//        status=on 2044:4998 / off 2044:4997 — 두 상태뿐. disabled·pressed 변형 없음.

import SwiftUI

/// 스위치 토글 — 50×28 트랙(g900) 안에서 20×20 노브가 좌우로 움직인다. 모서리 0(캡슐 아님).
/// 켜짐 노브 g500 / 꺼짐 g50 — 트랙 색은 두 상태가 같다.
///
/// 커스텀 `View` 가 아니라 `ToggleStyle` 인 이유: 그림만 우리 것이고
/// 바인딩 토글·탭 처리·`.disabled` 반응·접근성(switch trait)은 `Toggle` 이 이미 갖는다.
///
/// 라벨은 넘기면 토글 왼쪽에 p8 간격으로 붙는다(폭은 hug — 행 양끝 배치는 호출부가 `Spacer` 로).
/// 토글만 쓸 때는 `Toggle(isOn: $flag) { EmptyView() }` — `EmptyView` 는 간격을 만들지 않는다.
/// (`labelsHidden()` 은 커스텀 스타일에 듣지 않는다 — 그건 기본 스타일 전용이다.)
public struct HilitToggleStyle: ToggleStyle {
    /// 시안 수치 — spacing 토큰 스케일에 없는 컴포넌트 고유 크기라 상수로 둔다(`DashIndicator` 와 동일 방침).
    private enum Metric {
        static let width: CGFloat = 50
        static let height: CGFloat = 28
        static let knob: CGFloat = 20
        /// 트랙 폭 − 좌우 padding − 노브 = 50 − 8 − 20.
        static let travel: CGFloat = 22
    }

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .ds(.p8)) {
            configuration.label
            track(isOn: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture { configuration.isOn.toggle() }
        .accessibilityAddTraits(.isToggle)
    }

    private func track(isOn: Bool) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.GrayScale.g900)
            Rectangle()
                .fill(isOn ? Color.HilitGreen.g500 : Color.GrayScale.g50)
                .frame(width: Metric.knob, height: Metric.knob)
                .offset(x: isOn ? Metric.travel : 0)
                .padding(.ds(.p4))
        }
        .frame(width: Metric.width, height: Metric.height)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}

public extension ToggleStyle where Self == HilitToggleStyle {
    /// 스위치 토글 — `Toggle(isOn: $flag) { EmptyView() }.toggleStyle(.hilit)`.
    static var hilit: Self { HilitToggleStyle() }
}

#Preview("hilit toggle") {
    struct PreviewHost: View {
        @State private var on = true
        @State private var off = false

        var body: some View {
            VStack(alignment: .leading, spacing: .ds(.p20)) {
                Toggle(isOn: $on) { EmptyView() }
                Toggle(isOn: $off) { EmptyView() }
                Toggle(isOn: $on) { Text("라벨 동반").dsTypography(.body5) }
                Toggle(isOn: $off) { EmptyView() }.disabled(true)
            }
            .toggleStyle(.hilit)
            .padding(.ds(.p20))
            .background(Color.BlackWhite.white)
        }
    }
    return PreviewHost()
}
