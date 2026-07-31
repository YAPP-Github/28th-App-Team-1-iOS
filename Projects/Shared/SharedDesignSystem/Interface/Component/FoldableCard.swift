//
//  FoldableCard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «card» (folded / detail) https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=439-10343
// 케이스 매트릭스(Component System 3, 439:10241):
//   folded — 439:10343 max(335×71) · 439:10344 생성 실패 시 · 439:10345 포트폴리오 삭제 시 · 439:10346 태그 미존재
//   detail — 439:10347 max(335×174) · 439:10348 오류 문구 미노출 · 439:10349 버튼 미노출 · 439:10350 오류 문구만 노출

import SwiftUI

/// 접힌 요약 헤더 — Figma «card» `folded` 1:1.
///
/// 흰 판 + g100 1.5(`outline-sb`) 사방 테두리 · p14 · 가로 간격 12:
/// «제목 + (날짜·시각 + 메모 태그) / 상태 태그 / 쉐브론».
///
/// ```swift
/// Button { store.send(.view(.userTappedRecord)) } label: {
///     VStack(spacing: 0) {
///         FoldableCard("직군명 · n년차 면접", date: "2026.07.31", time: "14:30", isExpanded: expanded)
///         if expanded { FoldableCardDetail(rows) }
///     }
/// }
/// .buttonStyle(.plain)
/// ```
///
/// **탭은 이 타입이 갖지 않는다** — 펼침·이동 중 무엇이 걸리는지가 화면마다 달라서 규칙이 없다
/// (`CountdownCard` 와 같은 선택). 호출부가 통째로 감싼다. 펼쳐진 몸통은 `FoldableCardDetail` 이다.
///
/// Figma 의 «생성 실패 시 / 포트폴리오 삭제 시 / 태그 미존재» 축은 두 태그의 nil 로 표현한다.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct FoldableCard: View {
    private let title: String
    private let date: String?
    private let time: String?
    private let note: String?
    private let error: String?
    private let isExpanded: Bool

    /// - Parameters:
    ///   - title: 제목. 한 줄로 잘리고 넘치면 말줄임.
    ///   - date: 날짜. nil 이면 숨김.
    ///   - time: 시각. nil 이면 숨김.
    ///   - note: 날짜 뒤에 붙는 회색 메모 태그(«삭제된 포트폴리오»). nil 이면 숨김.
    ///   - error: 오른쪽 빨간 상태 태그(«생성 실패»). nil 이면 숨김.
    ///     시안에 red 한 종류만 있어 색을 닫았다 — 다른 색이 들어오면 그때 축을 연다.
    ///   - isExpanded: 쉐브론 방향. 접힘 ∨ / 펼침 ∧.
    public init(
        _ title: String,
        date: String? = nil,
        time: String? = nil,
        note: String? = nil,
        error: String? = nil,
        isExpanded: Bool = false
    ) {
        self.title = title
        self.date = date
        self.time = time
        self.note = note
        self.error = error
        self.isExpanded = isExpanded
    }

    public var body: some View {
        HStack(spacing: .ds(.p12)) {
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .dsTypography(.body2)
                    .foregroundStyle(Color.foldableCardTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if hasMeta {
                    metaRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let error {
                TagLabel(error, style: .redRed)
            }
            chevron
                .resizable()
                .scaledToFit()
                .frame(width: Metric.chevronSide, height: Metric.chevronSide)
        }
        .padding(.ds(.p14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.BlackWhite.white)
        .overlay {
            // 모서리 0 — 캡슐이 아니다.
            Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.semiBold))
        }
    }

    /// «날짜 시각» + 메모 태그. 날짜와 시각 사이엔 구분선이 없다(파일 카드와 다른 점).
    private var metaRow: some View {
        HStack(spacing: .ds(.p4)) {
            if date != nil || time != nil {
                HStack(spacing: .ds(.p4)) {
                    if let date {
                        metaText(date)
                    }
                    if let time {
                        metaText(time)
                    }
                }
            }
            if let note {
                TagLabel(note)
            }
        }
    }

    private func metaText(_ value: String) -> some View {
        // @ds(color): #9AA0AC → GrayScale.g300 — 시안 변수명은 레거시 컬렉션의 «gray/500» 인데
        // 값이 현행 g300(#9DA0AC)과 Δ3 로 사실상 같다. 이름(500)으로 읽으면 g500(#6D7183)이 되어 어긋난다.
        Text(value)
            .dsTypography(.body10)
            .foregroundStyle(Color.GrayScale.g300)
    }

    private var hasMeta: Bool {
        date != nil || time != nil || note != nil
    }

    private var chevron: Image {
        // 시안엔 접힘 판(`down/16px/default`)만 있다 — 펼침은 같은 패밀리의 `up` 으로 뒤집는다.
        isExpanded ? Image.Up.default : Image.Down.default
    }

    private enum Metric {
        /// 쉐브론 한 변 16 — Figma `down/16px`.
        static let chevronSide: CGFloat = 16
    }
}

/// 펼쳐진 몸통 — Figma «card» `detail` 1:1.
///
/// g100 판 · p14 · 세로 간격 12: «라벨/값 3줄 / 등폭 버튼 2개 / 폭 100% 오류 띠».
/// **`FoldableCard` 바로 아래에 붙는 전제**다 — 시안의 테두리가 좌우에만 있고(위는 헤더의 아래 테두리가
/// 대신한다) 색이 판과 같은 g100 이라 눈에 안 보인다. 그래서 테두리는 그리지 않고 판만 깐다.
///
/// ```swift
/// FoldableCardDetail(
///     [.init("직군 · 연차", "iOS · 3년"), .init("포트폴리오", "포트폴리오.pdf"), .init("JD", "링크")],
///     leadingAction: .init("레포트 보기") { … },
///     trailingAction: .init("지인 피드백 받기") { … }
/// )
/// ```
///
/// Figma 의 «버튼 미노출 / 오류 문구 미노출 / 오류 문구만 노출» 축은 값의 유무로 표현한다.
/// 버튼 배색은 시안대로 닫았다 — 왼쪽 흰 판(`.mini(.white)`), 오른쪽 검정(`.mini(.black)`).
public struct FoldableCardDetail: View {
    /// 라벨/값 한 줄. 라벨 열 폭은 70 고정이라 값이 어느 줄에서든 같은 x 에서 시작한다.
    public struct Row: Sendable, Hashable {
        let label: String
        let value: String

        public init(_ label: String, _ value: String) {
            self.label = label
            self.value = value
        }
    }

    /// 버튼 한 개 — 라벨과 동작만. 배색·크기는 이 타입이 시안대로 정한다.
    public struct Action {
        let title: String
        let handler: () -> Void

        public init(_ title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    private let rows: [Row]
    private let leadingAction: Action?
    private let trailingAction: Action?
    private let error: String?

    /// - Parameters:
    ///   - rows: 라벨/값 줄 (시안은 «직군 · 연차 / 포트폴리오 / JD» 3줄).
    ///   - leadingAction: 왼쪽 흰 버튼. nil 이면 숨김.
    ///   - trailingAction: 오른쪽 검정 버튼. nil 이면 숨김.
    ///   - error: 맨 아래 폭 100% 오류 띠 문구. nil 이면 숨김.
    public init(
        _ rows: [Row],
        leadingAction: Action? = nil,
        trailingAction: Action? = nil,
        error: String? = nil
    ) {
        self.rows = rows
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
        self.error = error
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ds(.p12)) {
            VStack(alignment: .leading, spacing: .ds(.p8)) {
                ForEach(rows, id: \.self) { row in
                    infoRow(row)
                }
            }
            if leadingAction != nil || trailingAction != nil {
                actionRow
            }
            if let error {
                errorBand(error)
            }
        }
        .padding(.ds(.p14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.GrayScale.g100)
    }

    private func infoRow(_ row: Row) -> some View {
        HStack(alignment: .top, spacing: .ds(.p4)) {
            Text(row.label)
                .lineLimit(1)
                .truncationMode(.tail)
                .dsTypography(.body7)
                .foregroundStyle(Color.GrayScale.g400)
                .frame(width: Metric.labelWidth, alignment: .leading)
            Text(row.value)
                .lineLimit(1)
                .truncationMode(.tail)
                .dsTypography(.body6)
                .foregroundStyle(Color.foldableCardValue)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 두 버튼이 남은 폭을 반씩 나눈다 — 늘어나는 건 라벨이다(`.frame` 을 Button 밖에 걸면
    /// 스타일이 이미 hug 로 그린 판은 안 늘어난다).
    private var actionRow: some View {
        HStack(spacing: .ds(.p8)) {
            if let leadingAction {
                actionButton(leadingAction, tone: .white)
            }
            if let trailingAction {
                actionButton(trailingAction, tone: .black)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(_ action: Action, tone: MiniButtonStyle.Tone) -> some View {
        Button(action: action.handler) {
            Text(action.title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.mini(tone))
    }

    /// 시안은 `tag`(0px family)를 폭 100% 로 늘려 쓴다 — `TagLabel` 은 내용폭 hug 라
    /// 판이 늘어나지 않아 여기선 같은 값(px4 · `body6` · e200/e500)으로 직접 그린다.
    private func errorBand(_ text: String) -> some View {
        Text(text)
            .dsTypography(.body6)
            .foregroundStyle(Color.Error.e500)
            .padding(.horizontal, .ds(.p4))
            .frame(maxWidth: .infinity)
            .background(Color.Error.e200)
    }

    private enum Metric {
        /// 라벨 열 폭 70 — 시안 고정값. 값 열의 시작 x 를 줄마다 맞추는 역할이다.
        static let labelWidth: CGFloat = 70
    }
}

private extension Color {
    /// 접힌 카드 제목 #3A3E47 — Figma 변수 미바인딩 raw 값이고 팔레트 23색 밖이다
    /// (g800 #31333B 와 g700 #494C58 사이). 같은 «card» 컴포넌트의 파일 카드 제목은
    /// `grayscale/gray-700` 으로 바인딩돼 있어 **시안끼리 어긋난다** — 디자이너 확인 대기.
    static let foldableCardTitle = Color(red: 58 / 255, green: 62 / 255, blue: 71 / 255)

    /// 상세 값 글자 #5D5C61 — Figma 변수 `gray/800`(팔레트 확정 전 레거시 컬렉션)인데 현행 팔레트에
    /// 대응이 없다(가장 가까운 g600 #636777 도 Δ22). 레거시 번호를 현행 800(#31333B)으로 읽으면
    /// 눈에 보이게 어두워진다 — 변수가 정리되면 팔레트 토큰으로 갈아탄다.
    static let foldableCardValue = Color(red: 93 / 255, green: 92 / 255, blue: 97 / 255)
}

// MARK: - Previews

/// 시안 프레임 335 = 화면 375 − 좌우 20. 실사용 폭은 호출부가 정한다.
private let previewFoldableCardWidth: CGFloat = 335

private let previewDetailRows: [FoldableCardDetail.Row] = [
    .init("직군 · 연차", "{직군명} · {n}년"),
    .init("포트폴리오", "{파일명}.pdf"),
    .init("JD", "{Link}")
]

#Preview("folded — 439:10343 · 10344 · 10345 · 10346") {
    VStack(spacing: .ds(.p20)) {
        // max case — 439:10343
        FoldableCard(
            "직군명 · n년차 면접",
            date: "{20xx.xx.xx}",
            time: "{xx:xx}",
            note: "삭제된 포트폴리오",
            error: "생성 실패"
        )
        // 생성 실패 시 — 439:10344
        FoldableCard("직군명 · n년차 면접", date: "{20xx.xx.xx}", time: "{xx:xx}", error: "생성 실패")
        // 포트폴리오 삭제 시 — 439:10345
        FoldableCard(
            "직군명 · n년차 면접",
            date: "{20xx.xx.xx}",
            time: "{xx:xx}",
            note: "삭제된 포트폴리오"
        )
        // 태그 미존재 — 439:10346
        FoldableCard("직군명 · n년차 면접", date: "{20xx.xx.xx}", time: "{xx:xx}")
        // 펼침 — 쉐브론만 뒤집힌다 (시안에 없는 판)
        FoldableCard("직군명 · n년차 면접", date: "{20xx.xx.xx}", time: "{xx:xx}", isExpanded: true)
    }
    .frame(width: previewFoldableCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("detail max — 439:10347") {
    FoldableCardDetail(
        previewDetailRows,
        leadingAction: .init("레포트 보기") {},
        trailingAction: .init("지인 피드백 받기") {},
        error: "오류 문구를 노출해주세요"
    )
    .frame(width: previewFoldableCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("detail 오류 문구 미노출 — 439:10348") {
    FoldableCardDetail(
        previewDetailRows,
        leadingAction: .init("레포트 보기") {},
        trailingAction: .init("지인 피드백 받기") {}
    )
    .frame(width: previewFoldableCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}

#Preview("detail 버튼 미노출 — 439:10349") {
    FoldableCardDetail(previewDetailRows)
        .frame(width: previewFoldableCardWidth)
        .padding(.ds(.p20))
        .background(Color.GrayScale.g50)
}

#Preview("detail 오류 문구만 노출 — 439:10350") {
    FoldableCardDetail(previewDetailRows, error: "오류 문구를 노출해주세요")
        .frame(width: previewFoldableCardWidth)
        .padding(.ds(.p20))
        .background(Color.GrayScale.g50)
}

#Preview("folded + detail — 펼친 한 장") {
    VStack(spacing: 0) {
        FoldableCard(
            "직군명 · n년차 면접",
            date: "{20xx.xx.xx}",
            time: "{xx:xx}",
            isExpanded: true
        )
        FoldableCardDetail(
            previewDetailRows,
            leadingAction: .init("레포트 보기") {},
            trailingAction: .init("지인 피드백 받기") {}
        )
    }
    .frame(width: previewFoldableCardWidth)
    .padding(.ds(.p20))
    .background(Color.GrayScale.g50)
}
