//
//  TabSelector.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/28.
//

// Figma: «tab» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2044-4765

import SwiftUI

/// 밑줄 탭 묶음 — 항목 배열 + 선택 바인딩을 받아 «선택된 하나만 밑줄» 규칙을 갖는다.
/// 조각(탭 하나)은 «선택 여부 → 밑줄·글자색» 뿐이라 공개하지 않고, 이 묶음만 공개한다.
/// Figma 시안은 탭 하나의 3변형(default/selected/disabled)만 있고 줄 배치는 없어
/// 항목 간 간격은 두지 않았다(각 탭의 px14 가 사이 여백 28 을 만든다).
///
/// `Tag` 는 선택 식별자 — 화면의 enum 을 그대로 쓴다.
public struct TabSelector<Tag: Hashable>: View {
    /// 탭 하나 — 라벨 + 식별자 + 활성 여부.
    public struct Item: Identifiable {
        let tag: Tag
        let title: String
        let isEnabled: Bool

        public var id: Tag { tag }

        /// - Parameters:
        ///   - tag: 선택 식별자. `selection` 과 같은 타입.
        ///   - title: 라벨.
        ///   - isEnabled: 끄면 회색·선택 불가. 묶음 전체를 끄려면 `TabSelector` 에 `.disabled(true)`.
        public init(tag: Tag, title: String, isEnabled: Bool = true) {
            self.tag = tag
            self.title = title
            self.isEnabled = isEnabled
        }
    }

    /// 폭을 어떻게 잡는가 — `.medium(layout:)` 과 같은 축.
    public enum Layout: Sendable {
        /// 라벨 크기만큼 (기본).
        case hug
        /// 주어진 폭을 균등 분할 — 화면 폭을 가득 채우는 탭 줄.
        case fill
    }

    private let items: [Item]
    private let layout: Layout
    @Binding private var selection: Tag

    /// - Parameters:
    ///   - items: 탭 항목. 순서가 표시 순서다.
    ///   - selection: 선택된 항목의 `tag`. 탭을 누르면 여기에 쓰고, 나머지는 자동으로 미선택이 된다.
    ///   - layout: `.hug` 기본 / `.fill` 균등 분할.
    public init(_ items: [Item], selection: Binding<Tag>, layout: Layout = .hug) {
        self.items = items
        self._selection = selection
        self.layout = layout
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button(item.title) { selection = item.tag }
                    .buttonStyle(TabButtonStyle(isSelected: selection == item.tag, isFill: layout == .fill))
                    .disabled(!item.isEnabled)
            }
        }
    }
}

/// 탭 하나 — h38 · px14/py8 · 선택 시 아래 1.5 밑줄.
/// 비활성은 색만 g500 으로 내려가고 밑줄은 그리지 않는다(선택될 수 없으니 시안에도 없다).
/// 글자는 16 SemiBold = `.body2`. 시안 행간 1.4·자간 -2% 는 토큰(1.3·-2.5%)과 미세하게 다르고
/// 그만큼 높이가 37 로 잡힌다 — 토큰 우선 규칙에 따라 토큰을 쓴다.
private struct TabButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let isSelected: Bool
    /// `Layout` 은 `TabSelector` 의 중첩 타입이라 `Tag` 마다 다른 타입이 된다 — 여기선 불리언으로 받는다.
    let isFill: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dsTypography(.body2)
            .lineLimit(1)
            .frame(maxWidth: isFill ? .infinity : nil)
            .padding(.horizontal, .ds(.p14))
            .padding(.vertical, .ds(.p8))
            .foregroundStyle(isEnabled ? Color.HilitBlack.b800 : Color.GrayScale.g500)
            .overlay(alignment: .bottom) {
                if isSelected, isEnabled {
                    Rectangle()
                        .fill(Color.HilitBlack.b800)
                        // @ds(spacing): 1.5 — Figma outline-sb (DSOutline 은 1.2 다음이 4)
                        .frame(height: 1.5)
                }
            }
            .contentShape(Rectangle())
    }
}

/// 선택이 살아 움직이는 걸 보려면 상태가 필요하다 — 프리뷰 전용 껍데기.
private struct TabSelectorPreview: View {
    @State private var selection = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            TabSelector(
                [
                    .init(tag: 0, title: "텍스트"),
                    .init(tag: 1, title: "텍스트"),
                    .init(tag: 2, title: "텍스트", isEnabled: false)
                ],
                selection: $selection
            )

            TabSelector(
                [
                    .init(tag: 0, title: "면접 질문"),
                    .init(tag: 1, title: "피드백"),
                    .init(tag: 2, title: "리포트")
                ],
                selection: $selection,
                layout: .fill
            )
        }
        .padding(.ds(.p20))
        .background(Color.BlackWhite.white)
    }
}

#Preview("tab — 선택·비활성") {
    TabSelectorPreview()
}
