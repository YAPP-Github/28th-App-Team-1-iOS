//
//  Modal.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/30.
//

// Figma: «modal» https://figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=2302-6098

import SwiftUI

/// 모달 카드 — 흰 판(아이콘·제목·서브텍스트·안내줄) + 하단 `ButtonLarge(.modal)`.
///
/// ```swift
/// Modal("텍스트를 입력해주세요",
///       subText: "서브텍스트를 입력해주세요",
///       icon: Image.Img.book,
///       info: "텍스트를 입력해주세요") {
///     ButtonLarge("버튼1", .modal) { }
/// }
/// ```
///
/// Figma 의 `showIcon`·`showSubText`·`showInfoField` 축은 각 파라미터의 nil 로 표현한다.
/// 아이콘은 instance-swap 슬롯이라 열어뒀다(`InfoField` 와 반대 — 모달마다 다른 일러스트가 실재).
/// 일러스트는 디자인된 크기 그대로 그린다 — `.frame` 으로 늘리지 않는다(`design/image.md`).
/// 버튼 슬롯엔 `ButtonLarge(.modal, …)` 단일/2버튼을 그대로 넣는다 — 배색·눌림은 그쪽 몫.
/// 폭은 고정하지 않는다 — 시안 327 은 화면 375 에서 좌우 여백 24 를 뺀 값이라 오버레이 몫.
/// 딤 배경·표시 전환·좌우 여백은 `.hilitModal` 오버레이가 준다 — 이 타입은 카드만 그린다.
public struct Modal<Buttons: View>: View {
    private let text: String
    private let subText: String?
    private let icon: Image?
    private let info: String?
    private let buttons: Buttons

    /// - Parameters:
    ///   - text: 제목. 폭이 모자라면 여러 줄 중앙 정렬로 흐른다.
    ///   - subText: 보조 설명. nil 이면 숨김 (Figma `showSubText=false`).
    ///   - icon: 상단 일러스트(`Image.Img.*`). nil 이면 숨김 (Figma `showIcon=false`).
    ///   - info: 안내줄 문구 — `InfoField(.gray)` 로 그린다. nil 이면 숨김 (Figma `showInfoField=false`).
    ///   - buttons: 하단 버튼 — `ButtonLarge(.modal, …)`.
    public init(
        _ text: String,
        subText: String? = nil,
        icon: Image? = nil,
        info: String? = nil,
        @ViewBuilder buttons: () -> Buttons
    ) {
        self.text = text
        self.subText = subText
        self.icon = icon
        self.info = info
        self.buttons = buttons()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
            buttons
        }
    }

    private var content: some View {
        VStack(spacing: .ds(.p20)) {
            if let icon {
                icon
            }
            textBlock
            if let info {
                InfoField(info)
            }
        }
        .padding(.horizontal, .ds(.p24))
        // @ds(spacing): 40 — 모달 판 세로 패딩 (spacing 토큰은 4~24 뿐)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
    }

    private var textBlock: some View {
        VStack(spacing: .ds(.p4)) {
            // @ds(color): #262A30 → GrayScale.g900 — 모달 제목. 시안 변수명은 «Gray scale/800»(값 #262A30)인데
            // Color Guide 의 800 은 #31333B 라 이름으론 안 맞는다. 값이 g900(#27282F)에 붙어 그쪽으로 맞췄다.
            Text(text)
                .dsTypography(.sub4)
                .foregroundStyle(Color.GrayScale.g900)
            if let subText {
                Text(subText)
                    .dsTypography(.body6)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

#Preview("전체 — 아이콘·서브텍스트·안내줄") {
    Modal(
        "텍스트를 입력해주세요",
        subText: "서브텍스트를 입력해주세요",
        icon: Image.Img.book,
        info: "텍스트를 입력해주세요"
    ) {
        ButtonLarge("버튼1", .modal) {}
    }
    // 시안 프레임 327 = 화면 375 − 좌우 24 — 실사용은 오버레이가 정한다.
    .frame(width: 327)
    .background(Color.HilitBlack.b900.opacity(0.5))
}

#Preview("텍스트만 + 2버튼") {
    Modal("정말 나가시겠어요?") {
        ButtonLarge(.modal, tone: .twoColor) {
            Button("취소") {}
        } trailing: {
            Button("나가기") {}
        }
    }
    .frame(width: 327)
}

#Preview("서브텍스트만") {
    Modal("텍스트를 입력해주세요", subText: "서브텍스트를 입력해주세요") {
        ButtonLarge("확인", .modal) {}
    }
    .frame(width: 327)
}
