//
//  NameField.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/29.
//

import SwiftUI

/// 이름 한 줄을 받는 밑줄 입력란 — Figma «name-field» 2192:5331 (`status` 축 2종).
///
/// 24pt 중앙 정렬 한 줄 + 아래 4pt 밑줄. `status` 는 파라미터가 아니라 **입력값에서 파생**한다 —
/// off(2192:5330) 는 비어 있을 때(g500 placeholder + g100 밑줄), on(2192:5329) 는 입력됐을 때
/// (b800 글자 + g600 밑줄)라 `text.isEmpty` 하나로 정해진다 (`TabSelector` 가 selection 에서
/// 밑줄을 파생시킨 것과 같은 이유 — 상태를 두 곳에서 관리하면 어긋난다).
///
/// **폭은 내용 hug** — 시안이 텍스트 폭만큼(167)이라 밑줄이 글자 길이를 따라간다.
/// 화면 가운데에 놓으려면 호출부가 `.frame(maxWidth: .infinity)` 를 건다.
/// 포커스·전송은 열지 않는다 — `.focused(_:)` 는 호출부가 직접 못 걸지만
/// `.onSubmit { }` 은 환경으로 내려가므로 밖에서 붙인다(`.submitLabel(.done)` 은 여기서 고정).
public struct NameField: View {
    private let placeholder: String
    @Binding private var text: String

    /// - Parameters:
    ///   - placeholder: 비어 있을 때 보일 문구. 도메인 문구는 호출부 몫이라 기본값을 두지 않는다.
    ///   - text: 입력값. 비어 있는지가 곧 Figma `status` 다.
    public init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        VStack(spacing: .ds(.p8)) {
            TextField(
                "",
                text: $text,
                // prompt 는 비어 있을 때만 — 남겨두면 입력 후에도 TextField 이상적 폭이 placeholder
                // 폭으로 잡혀, hug 되는 밑줄이 글자 길이를 따라가지 못한다.
                prompt: text.isEmpty
                    ? Text(placeholder).foregroundStyle(Color.GrayScale.g500)
                    : nil
            )
            .dsTypography(.head4)
            .foregroundStyle(Color.HilitBlack.b800)
            .multilineTextAlignment(.center)
            // 이름은 사전 교정·대문자 보정 대상이 아니다.
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            // 캐럿 색은 시안에 없다 — 시스템 기본 파랑이 팔레트 밖이라 메인 블랙으로 맞춘다.
            .tint(Color.HilitBlack.b800)

            Rectangle()
                .fill(text.isEmpty ? Color.GrayScale.g100 : Color.HilitGreen.g600)
                .frame(height: .ds(.large))
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    @Previewable @State var filled: String = "김은서"
    @Previewable @State var empty: String = ""

    VStack(spacing: .ds(.p24)) {
        NameField("이름을 알려주세요", text: $empty)
        NameField("이름을 알려주세요", text: $filled)
    }
    .frame(maxWidth: .infinity)
    .padding(.ds(.p20))
    .background(Color.BlackWhite.white)
}
