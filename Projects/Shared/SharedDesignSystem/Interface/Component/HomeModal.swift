//
//  HomeModal.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «home modal» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-1565
// `property1` 축: 439:10408 opp · 439:10409 port (Component System 3, 439:10241).

import SwiftUI

/// 홈 모달 카드 — 흰 판(일러스트·서브타이틀·타이틀·안내줄/딸린 카드), **버튼 없음**.
///
/// ```swift
/// HomeModal("이번 주 추천 공고예요",
///           subTitle: "지원 마감 D-3",
///           icon: Image.Img.oppO,
///           info: "텍스트를 입력해주세요")
/// ```
///
/// `Modal` 과 왜 별 타입인가 — 시안이 두 곳에서 어긋난다: ① 텍스트 순서가 뒤집혀 있다
/// (**서브타이틀이 타이틀 위**) ② 버튼 슬롯이 없다. `Modal` 을 넓혀 덮으면 순서 축과
/// 버튼 유무 축이 새로 생겨 «시안에 없는 조합»이 표현 가능해진다(사고 사례 5번).
/// 타이틀 색도 다르다 — `Modal` 은 레거시 `Gray scale/800`(#262A30 → `g900`)인데
/// 여기는 현행 `hilit black/800`(#1A1B1F → `b800`) 으로 정확히 붙는다.
///
/// 판 패딩은 네 변 모두 24 (`Modal` 은 px24·py40), 세로 리듬은 12.
/// 일러스트는 74pt 판 그대로 그린다 — `.frame` 으로 늘리지 않는다(`design/image.md`).
/// 폭은 고정하지 않는다 — 시안 327 은 화면 375 에서 좌우 24 를 뺀 값이라 오버레이 몫.
/// 딤 배경·표시 전환·좌우 여백은 `.hilitModal` 오버레이가 준다 — 이 타입은 카드만 그린다.
///
/// `content` 슬롯은 `property1=port` 케이스용이다 — 시안의 port 는 일러스트·서브타이틀 없이
/// 타이틀 한 줄 + 파일 카드(`card-pdf` max 439:10334)를 얹는다. 그 카드는 독립 컴포넌트
/// (`FileCard`)라 이 타입이 조립하지 않고 슬롯으로 열어 둔다 — 호출부가 넣는다.
public struct HomeModal<Content: View>: View {
    private let title: String
    private let subTitle: String?
    private let icon: Image?
    private let info: String?
    private let content: Content

    /// - Parameters:
    ///   - title: 타이틀. 폭이 모자라면 여러 줄 중앙 정렬로 흐른다.
    ///   - subTitle: 타이틀 **위**에 놓이는 보조 설명. nil 이면 숨김.
    ///   - icon: 상단 74pt 일러스트(`Image.Img.oppO` 등). nil 이면 숨김 (Figma `property1=port`).
    ///   - info: 안내줄 문구 — `InfoField(.gray)` 로 그린다. nil 이면 숨김 (Figma `showInfoField=false`).
    ///   - content: 안내줄 아래 딸린 뷰 — port 케이스의 파일 카드 자리. 기본 없음.
    public init(
        _ title: String,
        subTitle: String? = nil,
        icon: Image? = nil,
        info: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subTitle = subTitle
        self.icon = icon
        self.info = info
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: .ds(.p12)) {
            if let icon {
                icon
            }
            textBlock
            if let info {
                InfoField(info)
            }
            content
        }
        .padding(.ds(.p24))
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
    }

    /// 서브타이틀이 **위**, 타이틀이 아래 — `Modal.textBlock` 과 순서가 반대다.
    private var textBlock: some View {
        VStack(spacing: .ds(.p4)) {
            if let subTitle {
                Text(subTitle)
                    .dsTypography(.body6)
                    .foregroundStyle(Color.GrayScale.g500)
            }
            Text(title)
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

public extension HomeModal where Content == EmptyView {
    /// 딸린 뷰 없는 홈 모달 (Figma `property1=opp`).
    init(
        _ title: String,
        subTitle: String? = nil,
        icon: Image? = nil,
        info: String? = nil
    ) {
        self.init(title, subTitle: subTitle, icon: icon, info: info) { EmptyView() }
    }
}

// MARK: - Previews

/// 시안 프레임 327 = 화면 375 − 좌우 24. 실사용 폭은 `.hilitModal` 이 정한다.
private let previewHomeModalWidth: CGFloat = 327

#Preview("opp — 439:10408") {
    HomeModal(
        "title",
        subTitle: "sub-title",
        icon: Image.Img.oppO,
        info: "텍스트를 입력해주세요"
    )
    .frame(width: previewHomeModalWidth)
    .background(Color.HilitBlack.b900.opacity(0.5))
}

#Preview("opp — 인포박스 미노출") {
    HomeModal("title", subTitle: "sub-title", icon: Image.Img.oppO)
        .frame(width: previewHomeModalWidth)
}

#Preview("port — 439:10409") {
    // 시안 port 가 얹는 `card-pdf`(max 439:10334) = `FileCard`.
    HomeModal("등록한 포트폴리오") {
        FileCard("{파일명}.pdf", date: "{20xx.xx.xx}", size: "{0}mb")
    }
    .frame(width: previewHomeModalWidth)
}
