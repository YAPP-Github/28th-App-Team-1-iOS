//
//  HilitTextField.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/30.
//

// Figma: «text-field» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2044-1801

import SwiftUI

/// 한 줄 입력 필드 — Figma «text-field» 6변형(default/focused/typing/loading/success/error) + 카운터 조합(2044:1623).
/// SwiftUI `TextField` 와 이름이 겹쳐 `Hilit` 접두를 붙였다.
///
/// 상태는 두 축으로 갈라 받는다:
/// - **포커스·타이핑은 넘기지 않는다** — `@FocusState` 와 `text.isEmpty` 에서 파생한다
///   (버튼이 pressed 를 안 받는 것과 같은 이유). 포커스 중엔 아래 4pt 초록 바, 글자가 있으면 클리어 버튼.
/// - **의미 상태(`Status`)만 파라미터** — 분석 중·성공·실패는 밖(리듀서)만 알 수 있다.
///
/// 서브 줄은 `FieldSubText` 로 그리고 스타일은 status 가 정한다(idle→info · success/error→같은 이름).
/// 시안대로 포커스 중(focused/typing)과 loading 엔 서브 줄을 그리지 않는다.
/// 클리어 버튼 자리는 글자가 없어도 늘 잡아둔다(시안 opacity 0 — 입력 폭 흔들림 방지).
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
///
/// > Figma 원본 불일치: loading 라벨 색이 text-field(2044:1798)는 g400, 카운터 조합(2286:5661)은 g900 —
/// > 컴포넌트 세트 쪽(g400)으로 구현했다. 디자이너 확인 대기.
public struct HilitTextField: View {
    /// 의미 상태 — 포커스·타이핑은 여기 없다(내부 파생).
    public enum Status: Equatable, Sendable {
        /// 평상시. 테두리·초록 바는 포커스가 결정한다.
        case idle
        /// 분석 중 — 입력 잠금 + g100 판 + 오른쪽 라벨 + 진행 바.
        /// 라벨(시안 «분석 중»)은 도메인 어휘라 밖에서 받는다.
        case loading(String)
        /// 성공 — 초록 바, `subText` 는 초록 서브 줄로.
        case success
        /// 실패 — 빨간 바, `subText` 는 빨간 서브 줄로.
        case error
    }

    private let placeholder: String
    @Binding private var text: String
    private let status: Status
    private let subText: String?
    private let maxLength: Int?

    @FocusState private var isFocused: Bool

    /// - Parameters:
    ///   - placeholder: 빈 필드 안내 문구.
    ///   - text: 입력 값.
    ///   - status: 의미 상태. 기본 `.idle`.
    ///   - subText: 필드 아래 서브 줄. 스타일은 status 가 정하고, 포커스 중·loading 엔 숨는다.
    ///   - maxLength: 주면 아래 오른쪽에 «n/max» 카운터를 그리고 초과 입력을 잘라낸다.
    public init(
        _ placeholder: String,
        text: Binding<String>,
        status: Status = .idle,
        subText: String? = nil,
        maxLength: Int? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.status = status
        self.subText = subText
        self.maxLength = maxLength
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p8)) {
            field
            if let maxLength {
                Text(verbatim: "\(text.count)/\(maxLength)")
                    .dsTypography(.body9)
                    .foregroundStyle(Color.GrayScale.g500)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if let subText, let subStatus {
                FieldSubText(subText, status: subStatus)
            }
        }
        .onChange(of: text) { _, newValue in
            if let maxLength, newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
        }
    }

    // MARK: - 필드 박스

    private var field: some View {
        VStack(spacing: 0) {
            HStack(spacing: .ds(.p4)) {
                TextField("", text: $text, prompt: prompt)
                    .dsTypography(.body4)
                    .foregroundStyle(Color.HilitBlack.b800)
                    .focused($isFocused)
                    .disabled(isLoading)
                trailing
            }
            .padding(.horizontal, .ds(.p16))
            .padding(.vertical, .ds(.p14))
            .background(isLoading ? Color.GrayScale.g100 : Color.BlackWhite.white)
            .overlay { border }
            underline
        }
    }

    private var prompt: Text {
        Text(placeholder)
            .font(.ds(.body4))
            .foregroundStyle(Color.GrayScale.g500)
    }

    /// 오른쪽 끝 — loading 은 라벨, 그 밖엔 클리어 버튼(글자 없으면 투명하게 자리만).
    @ViewBuilder private var trailing: some View {
        if case let .loading(label) = status {
            Text(label)
                .dsTypography(.body9)
                .foregroundStyle(Color.GrayScale.g400)
                .lineLimit(1)
        } else {
            Button {
                text = ""
            } label: {
                Image.CancelMini.gray16
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.iconSide, height: Metric.iconSide)
            }
            .buttonStyle(.plain)
            .opacity(text.isEmpty ? 0 : 1)
            .disabled(text.isEmpty)
        }
    }

    /// 아래 바가 있으면 테두리는 ㄷ자(아래 변은 바가 닫는다), 없으면 4변.
    @ViewBuilder private var border: some View {
        if showsBar {
            OpenBottomBorder(lineWidth: .ds(.medium))
                .stroke(Color.GrayScale.g100, lineWidth: .ds(.medium))
        } else {
            Rectangle()
                .strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.medium))
        }
    }

    @ViewBuilder private var underline: some View {
        if case .loading = status {
            IndeterminateProgressBar()
        } else if let barColor {
            Rectangle()
                .fill(barColor)
                .frame(height: .ds(.large))
        }
    }

    // MARK: - 상태 파생

    private var isLoading: Bool {
        if case .loading = status { return true }
        return false
    }

    private var showsBar: Bool {
        switch status {
        case .idle: isFocused
        case .loading, .success, .error: true
        }
    }

    private var barColor: Color? {
        switch status {
        case .idle: isFocused ? Color.HilitGreen.g500 : nil
        case .loading: nil // 진행 바가 대신 그린다
        case .success: Color.HilitGreen.g500
        case .error: Color.Error.e500
        }
    }

    private var subStatus: FieldSubText.Status? {
        switch status {
        case .idle: isFocused ? nil : .info // 시안: focused/typing 변형엔 서브 줄이 없다
        case .loading: nil
        case .success: .success
        case .error: .error
        }
    }

    private enum Metric {
        /// 클리어 아이콘 한 변 16 — Figma cancel mini/16px.
        static let iconSide: CGFloat = 16
    }
}

/// 아래 변이 뚫린 ㄷ자 테두리 — 아래는 상태 바(4pt)가 대신 닫는다.
/// `strokeBorder` 는 닫힌 InsettableShape 전용이라, 선 중심을 반 두께 안쪽으로 들여
/// `stroke` 가 프레임 밖으로 번지지 않게 했다.
private struct OpenBottomBorder: Shape {
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = lineWidth / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        return path
    }
}

/// 분석 중 진행 바 — g200 트랙 위를 g500 조각이 왼→오로 도는 무한 애니메이션.
/// 시안(2044:1798)은 이동 중 한 프레임(160/100/나머지)이라 조각 폭 100 만 시안 값이다.
private struct IndeterminateProgressBar: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.GrayScale.g200)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.HilitGreen.g500)
                        .frame(width: Metric.segmentWidth)
                        .offset(x: isAnimating ? geometry.size.width : -Metric.segmentWidth)
                }
                .clipped()
        }
        .frame(height: .ds(.large))
        .onAppear {
            withAnimation(.linear(duration: Metric.cycle).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    private enum Metric {
        /// 초록 조각 폭 — 시안 스냅숏의 초록 구간.
        static let segmentWidth: CGFloat = 100
        static let cycle: TimeInterval = 1.2
    }
}

/// 포커스·타이핑이 살아 움직이는 걸 보려면 상태가 필요하다 — 프리뷰 전용 껍데기.
private struct HilitTextFieldPreview: View {
    @State private var text = ""
    @State private var counted = ""

    var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p20)) {
            HilitTextField("텍스트를 입력해주세요", text: $text, subText: "서브 텍스트를 입력해주세요")
            HilitTextField("텍스트를 입력해주세요", text: .constant(""), status: .loading("분석 중"))
            HilitTextField("텍스트를 입력해주세요", text: .constant("입력한 텍스트"), status: .success, subText: "서브 텍스트를 입력해주세요")
            HilitTextField("텍스트를 입력해주세요", text: .constant("입력한 텍스트"), status: .error, subText: "서브 텍스트를 입력해주세요")
            HilitTextField("텍스트를 입력해주세요", text: $counted, maxLength: 300)
        }
        .padding(.ds(.p20))
        .background(Color.BlackWhite.white)
    }
}

#Preview("text-field — 상태별") {
    HilitTextFieldPreview()
}
