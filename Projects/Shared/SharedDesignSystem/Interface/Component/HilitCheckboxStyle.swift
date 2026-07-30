//
//  HilitCheckboxStyle.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/29.
//

// Figma: «Checkbox» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3768-16630
//        status=Checked 3768:16628 / Indeterminate 3768:16627 — 두 상태뿐. disabled·pressed 변형 없음.
//        (Figma 의 «Indeterminate» 는 세 번째 상태가 아니라 꺼짐이다 — 이름만 그렇게 붙어 있다.)

import SwiftUI

/// 체크박스 — 24×24 직각 사각형. 모서리 0(원형 아님).
/// 켜짐 배경 b800 + 체크 `Image.Check.green` / 꺼짐 배경 white + 테두리 1.6 g200 + `Image.Check.gray`(유령 체크).
///
/// 커스텀 `View` 가 아니라 `ToggleStyle` 인 이유는 [`HilitToggleStyle`](HilitToggleStyle.swift) 와 같다 —
/// 그림만 우리 것이고 on/off 상태·바인딩 토글은 `Toggle` 이 이미 갖는다.
/// 탭은 안에 심은 `Button` 이 받는다 — 클릭 이벤트·`.disabled` 차단·접근성(버튼 trait)이 공짜로 따라온다.
///
/// 라벨은 넘기면 체크박스 **오른쪽**에 p8 간격으로 붙고 같이 탭된다(스위치인 `.hilit` 은 라벨이 왼쪽 —
/// 체크박스는 목록 행에서 박스가 앞에 서는 쪽이 관례다). 시안에 라벨이 없어 배치는 관례를 따랐다.
/// 박스만 쓸 때는 `Toggle(isOn: $flag) { EmptyView() }` — `EmptyView` 는 간격을 만들지 않는다.
public struct HilitCheckboxStyle: ToggleStyle {
    /// 시안 수치 — 테두리 1.6 은 `DSOutline` 스케일(1·1.2·4·6)에 없는 컴포넌트 고유 값이라 상수로 둔다.
    private enum Metric {
        static let box: CGFloat = 24
        static let border: CGFloat = 1.6
        /// 체크가 가로는 정중앙, 세로는 0.5 아래에 놓인다(시안 checked 기준).
        static let markOffsetY: CGFloat = 0.5
    }

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: .ds(.p8)) {
                box(isOn: configuration.isOn)
                configuration.label
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
    }

    private func box(isOn: Bool) -> some View {
        ZStack {
            if isOn {
                Rectangle()
                    .fill(Color.HilitBlack.b800)
            } else {
                Rectangle()
                    .fill(Color.BlackWhite.white)
                Rectangle()
                    .strokeBorder(Color.GrayScale.g200, lineWidth: Metric.border)
            }
            (isOn ? Image.Check.green : Image.Check.gray)
                .offset(y: Metric.markOffsetY)
        }
        .frame(width: Metric.box, height: Metric.box)
    }
}

public extension ToggleStyle where Self == HilitCheckboxStyle {
    /// 체크박스 — `Toggle(isOn: $flag) { EmptyView() }.toggleStyle(.hilitCheckbox)`.
    /// (`.checkbox` 는 macOS 기본 스타일 이름이라 접두사를 붙인다.)
    static var hilitCheckbox: Self { HilitCheckboxStyle() }
}

#Preview("hilit checkbox") {
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
            .toggleStyle(.hilitCheckbox)
            .padding(.ds(.p20))
            .background(Color.BlackWhite.white)
        }
    }
    return PreviewHost()
}
