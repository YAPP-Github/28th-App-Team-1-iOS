//
//  StartInterviewView.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

// Figma: «Home_StartInterview»             https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-1612
//        «Home_StartInterview_SameContext» https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-13730
//        «Home_StartInterview_TrialEnded»  https://www.figma.com/design/ZG7FUxWCvITmnvzZi7fpTS/?node-id=3632-9566

import ComposableArchitecture
import Foundation
import SharedDesignSystemInterface
import SwiftUI

/// 면접 시작 — 시안 3장을 `StartInterviewFeature.Variant` 로 분기한다.
///
/// 세 시안의 골격은 같다: 커튼 그린 배경 + 좌상단 인사말(color-burn) + 중앙 흰 카드 + 하단 CTA.
/// 갈리는 건 **인사말 문구 · 카드 내용 · CTA** 셋이다.
///
/// **화면이 아니라 홈 씬의 한 겹**이다 — 리포트 시트 뒤에 늘 깔려 있고 시트가 내려간 만큼 드러난다
/// (`HomeView`). 그래서 그린 배경·내비바를 여기서 갖지 않는다. 나가기(X)는 홈 내비바가 «시트를 도로
/// 올린다» 로 처리한다 — 소진 시안엔 시안상 바가 없지만, 씬에 늘 바가 있어 X 도 함께 뜬다
/// (하단 «홈으로» 와 결과가 같아 해롭지 않다).
///
/// 카드 안 값(잔여 횟수·포트폴리오 파일 정보)은 `StartInterviewFeature.State` 소유고,
/// 표기(«2026.07.31»·«3.2mb»)만 이 뷰가 만든다.
@ViewAction(for: StartInterviewFeature.self)
public struct StartInterviewView: View {
    @Bindable public var store: StoreOf<StartInterviewFeature>

    public init(store: StoreOf<StartInterviewFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            greeting
                // @ds(spacing): 54 — 내비바 아래 ~ 인사말 (시안 프레임 top 141 − 상태바 43 − 내비바 44)
                .padding(.top, 54)
                // @ds(spacing): 80 — 인사말 아래 ~ 카드 위 (시안 텍스트 bottom 255 → 카드 top 335). spacing 토큰은 4~24
                .padding(.bottom, 80)
            card
            Spacer(minLength: 0)
            callToAction
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 인사말

    private var greeting: some View {
        Text(greetingText)
            .dsTypography(.head1)
            .foregroundStyle(Color.HilitBlack.b800)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .ds(.p20))
            // @ds(component): mix-blend-mode color-burn — 인사말이 배경 커튼과 타서 초록으로 보이는 효과. DS 에 블렌드 규칙 없음
            .blendMode(.colorBurn)
    }

    /// 시안의 줄바꿈을 그대로 옮긴다 — 세 시안 모두 3줄 고정 폭에 맞춰 끊어져 있다.
    /// 이름은 프로필 로드 결과라 응답 전엔 비어 있다 — 그때는 «님,» 만 남지 않게 이름 줄을 뺀다.
    private var greetingText: String {
        let namePrefix = store.userName.isEmpty ? "" : "\(store.userName)님,\n"
        switch store.variant {
        case .first: return namePrefix + "지금부터 면접을\n시작해 볼까요?"
        case .hasPortfolio: return "이전과\n동일한 정보로\n시작할까요?"
        case .exhausted: return namePrefix + "무료 횟수를 모두\n사용했어요"
        }
    }

    // MARK: - 카드

    @ViewBuilder private var card: some View {
        switch store.variant {
        case .first:
            remainingChancesCard(icon: Image.Img.oppO)
        case .hasPortfolio:
            portfolioCard
        case .exhausted:
            remainingChancesCard(icon: Image.Img.oppX)
        }
    }

    /// 잔여 횟수 카드 — Figma «home modal» property1=opp (3632:10988). 일러스트 + 보조문구 + 값.
    /// 시안의 `showInfoField` 축은 두 시안 모두 false 라 안내줄을 두지 않았다.
    private func remainingChancesCard(icon: Image) -> some View {
        modalCard {
            icon
            VStack(spacing: .ds(.p4)) {
                Text("남은 면접 기회")
                    .dsTypography(.body6)
                    .foregroundStyle(Color.GrayScale.g500)
                // 잔여를 모르는 동안(프로필 응답 전·실패)엔 숫자 줄을 뺀다 — «0회» 로 떨어뜨리면
                // 서버가 말하지 않은 소진을 화면이 지어낸다(포폴 날짜·용량과 같은 규칙).
                if let remainingChances = store.remainingChances {
                    Text("\(remainingChances)회")
                        .dsTypography(.sub4)
                        .foregroundStyle(Color.HilitBlack.b800)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    /// 등록 포트폴리오 카드 — Figma «home modal» property1=port (3632:13862). 제목 + 파일 한 줄.
    @ViewBuilder private var portfolioCard: some View {
        modalCard {
            Text("등록한 포트폴리오")
                .dsTypography(.sub4)
                .foregroundStyle(Color.HilitBlack.b800)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if let portfolio = store.portfolio {
                portfolioFileRow(portfolio)
            }
        }
    }

    /// 파일 한 줄 — Figma «card» 3632:13817. 36 파일 아이콘 + 파일명 + «날짜 | 용량».
    /// 날짜·용량 표기는 여기서 만든다 — State 는 원값(`Date`·바이트)만 든다.
    private func portfolioFileRow(_ portfolio: StartInterviewFeature.Portfolio) -> some View {
        HStack(spacing: .ds(.p12)) {
            Image.File.green36
            VStack(alignment: .leading, spacing: .ds(.p4)) {
                Text(portfolio.fileName)
                    .dsTypography(.body2)
                    .foregroundStyle(Color.GrayScale.g700)
                    .lineLimit(1)
                    .truncationMode(.tail)
                // 날짜·용량은 서버가 안 줄 수 있다 — 없는 조각과 그 구분선만 빼고 나머지는 그대로 그린다.
                HStack(spacing: .ds(.p4)) {
                    if let uploadedAt = portfolio.uploadedAt {
                        metaText(Self.uploadedAtText(uploadedAt))
                    }
                    if portfolio.uploadedAt != nil, portfolio.byteCount != nil {
                        Rectangle()
                            .fill(Color.GrayScale.g200)
                            .frame(width: .ds(.medium), height: .ds(.p10))
                    }
                    if let byteCount = portfolio.byteCount {
                        metaText(Self.sizeText(byteCount))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.ds(.p14))
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
        .overlay {
            // @ds(spacing): 1.5 (outline-sb) — 파일 카드 테두리 두께 (DSOutline 는 1·1.2·4·6)
            Rectangle()
                .strokeBorder(Color.GrayScale.g100, lineWidth: 1.5)
        }
    }

    /// 파일 한 줄 아래 메타 조각(날짜·용량) — 두 조각이 같은 타이포·색이라 한 자리에 모은다.
    private func metaText(_ text: String) -> some View {
        Text(text)
            .dsTypography(.body10)
            .foregroundStyle(Color.GrayScale.g400)
    }

    /// 업로드일 표기 «2026.07.31» — 시안 표기(`{20xx.xx.xx}`)를 그대로 옮긴 고정 포맷이라 로케일에 흔들리지 않게 둔다.
    ///
    /// 타임존도 **KST 고정**이다 — 서버가 타임존 없는 LocalDateTime 을 주고 디코더가 그걸 KST 로
    /// 읽는데(`JSONDecoder.api`), 표시만 기기 로컬로 두면 UTC 서쪽 기기에서 하루 밀린 날짜가 뜬다.
    /// 읽는 쪽과 쓰는 쪽이 같은 가정을 써야 한다(백엔드와 타임존 계약 확정 시 두 곳을 같이 고친다).
    private static let uploadedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static func uploadedAtText(_ date: Date) -> String {
        uploadedAtFormatter.string(from: date)
    }

    /// 용량 표기 «3.2mb» — 시안 표기(`{0}mb`)의 소문자 단위·MB 기준을 따른다.
    private static func sizeText(_ byteCount: Int) -> String {
        let megabytes = Double(byteCount) / 1_048_576
        return String(format: "%.1fmb", megabytes)
    }

    /// 흰 카드 판 — Figma «home modal» (p24 · gap12 · 모서리 0 · 폭 327 = 375 − 24×2).
    // @ds(component): «home modal» — DS `Modal`(py40 · gap20 · 제목이 서브텍스트 위)과 리듬이 다른 별개 가족. 공용 컴포넌트 없음
    private func modalCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: .ds(.p12)) {
            content()
        }
        .padding(.ds(.p24))
        .frame(maxWidth: .infinity)
        .background(Color.BlackWhite.white)
        .padding(.horizontal, .ds(.p24))
    }

    // MARK: - 하단 CTA

    @ViewBuilder private var callToAction: some View {
        switch store.variant {
        case .first:
            ButtonLarge("시작하기", .bottom) { send(.userTappedStart) }
        case .hasPortfolio:
            ButtonLarge(.bottom, tone: .dark) {
                Button("수정하기") { send(.userTappedEditInfo) }
            } trailing: {
                Button("시작하기") { send(.userTappedStart) }
            }
        case .exhausted:
            ButtonLarge("홈으로", .bottom) { send(.userTappedBackToHome) }
        }
    }
}

// MARK: - Previews

/// 씬의 한 겹이라 단독으로는 배경이 없다 — 프리뷰에서만 홈이 깔아 주는 배경을 흉내 낸다.
/// State 기본값은 중립(이름 없음·잔여 미확정·포폴 없음)이라 **시안 값은 여기서 명시로 넘긴다**.
private func previewLayer(
    _ variant: StartInterviewFeature.Variant,
    remainingChances: Int?
) -> some View {
    ZStack {
        HomeGreenBackdrop()
            .ignoresSafeArea()
        StartInterviewView(
            store: Store(
                initialState: StartInterviewFeature.State(
                    variant: variant,
                    userName: "재원",
                    remainingChances: remainingChances,
                    portfolio: variant == .hasPortfolio ? .placeholder : nil
                )
            ) {
                StartInterviewFeature()
            }
        )
    }
    .compositingGroup()
}

#Preview("처음 — 정보 입력 전") {
    previewLayer(.first, remainingChances: 3)
}

#Preview("이전 정보 재사용") {
    previewLayer(.hasPortfolio, remainingChances: 3)
}

#Preview("무료 횟수 소진") {
    previewLayer(.exhausted, remainingChances: 0)
}

// 프로필이 죽었거나 아직 안 온 자리 — 숫자 줄만 빠지고 시작 경로는 살아 있다.
#Preview("처음 — 잔여 미확정") {
    previewLayer(.first, remainingChances: nil)
}
