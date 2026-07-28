//
//  CatalogImageView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 이미지 토큰 전체 — 패밀리 30개 · 127개 토큰. `static var` 묶음이라 순회가 안 돼 손으로 열거한다
/// (목록은 `Image+Extension.swift` 에서 기계적으로 뽑았다 — 에셋을 추가하면 여기도 한 줄 추가).
///
/// 실제 크기는 토큰 이름에 있다(`default16`·`dark24`) — 타일에서는 비교를 위해 같은 칸에 맞춰 그린다.
/// 흰 아이콘(`white…`)은 밝은 배경에서 안 보여 타일 배경을 어둡게 깐다. 틴트는 걸지 않는다(색은 에셋에 구움).
struct CatalogImageView: View {
    private struct Family: Identifiable {
        let name: String
        let members: [(name: String, image: Image)]
        var id: String { name }
    }

    private let families: [Family] = [
        Family(name: "Ai", members: [
            ("green", Image.Ai.green),
        ]),
        Family(name: "Cancel", members: [
            ("dark16", Image.Cancel.dark16),
            ("dark20", Image.Cancel.dark20),
            ("dark24", Image.Cancel.dark24),
            ("default24", Image.Cancel.default24),
            ("disabled24", Image.Cancel.disabled24),
        ]),
        Family(name: "CancelMini", members: [
            ("black16", Image.CancelMini.black16),
            ("black24", Image.CancelMini.black24),
            ("grey16", Image.CancelMini.grey16),
            ("grey24", Image.CancelMini.grey24),
        ]),
        Family(name: "Coupon", members: [
            ("default", Image.Coupon.default),
            ("disabled", Image.Coupon.disabled),
        ]),
        Family(name: "Down", members: [
            ("dark", Image.Down.dark),
            ("default", Image.Down.default),
            ("disabled", Image.Down.disabled),
        ]),
        Family(name: "Edit", members: [
            ("default16", Image.Edit.default16),
            ("default24", Image.Edit.default24),
            ("disabled16", Image.Edit.disabled16),
            ("disabled24", Image.Edit.disabled24),
        ]),
        Family(name: "Expand", members: [
            ("default24", Image.Expand.default24),
            ("default30", Image.Expand.default30),
        ]),
        Family(name: "Feedback", members: [
            ("body20", Image.Feedback.body20),
            ("body24", Image.Feedback.body24),
            ("body28", Image.Feedback.body28),
            ("eyes20", Image.Feedback.eyes20),
            ("eyes24", Image.Feedback.eyes24),
            ("eyes28", Image.Feedback.eyes28),
            ("face20", Image.Feedback.face20),
            ("face24", Image.Feedback.face24),
            ("face28", Image.Feedback.face28),
            ("hand20", Image.Feedback.hand20),
            ("hand24", Image.Feedback.hand24),
            ("hand28", Image.Feedback.hand28),
            ("voice20", Image.Feedback.voice20),
            ("voice24", Image.Feedback.voice24),
            ("voice28", Image.Feedback.voice28),
        ]),
        Family(name: "File", members: [
            ("dark16", Image.File.dark16),
            ("dark20", Image.File.dark20),
            ("dark24", Image.File.dark24),
            ("default16", Image.File.default16),
            ("default20", Image.File.default20),
            ("default24", Image.File.default24),
            ("disabled16", Image.File.disabled16),
            ("disabled20", Image.File.disabled20),
            ("disabled24", Image.File.disabled24),
        ]),
        Family(name: "Img", members: [
            ("book", Image.Img.book),
            ("link", Image.Img.link),
            ("micError", Image.Img.micError),
            ("networkError", Image.Img.networkError),
            ("tooltipTail", Image.Img.tooltipTail),
        ]),
        Family(name: "Info", members: [
            ("default", Image.Info.default),
            ("disabled", Image.Info.disabled),
        ]),
        Family(name: "Issue", members: [
            ("default16", Image.Issue.default16),
            ("default20", Image.Issue.default20),
            ("default24", Image.Issue.default24),
            ("error16", Image.Issue.error16),
            ("error20", Image.Issue.error20),
            ("error24", Image.Issue.error24),
        ]),
        Family(name: "Left", members: [
            ("dark", Image.Left.dark),
            ("default", Image.Left.default),
            ("disabled", Image.Left.disabled),
        ]),
        Family(name: "Loading", members: [
            ("dark24", Image.Loading.dark24),
            ("ingDark16", Image.Loading.ingDark16),
            ("ingGreen24", Image.Loading.ingGreen24),
            ("ingGrey16", Image.Loading.ingGrey16),
            ("ingWhite16", Image.Loading.ingWhite16),
            ("successDark16", Image.Loading.successDark16),
            ("successDark24", Image.Loading.successDark24),
            ("successGreen24", Image.Loading.successGreen24),
            ("successGrey16", Image.Loading.successGrey16),
            ("waitDark16", Image.Loading.waitDark16),
            ("waitGrey16", Image.Loading.waitGrey16),
            ("waitWhite16", Image.Loading.waitWhite16),
            ("white24", Image.Loading.white24),
        ]),
        Family(name: "Logo", members: [
            ("appleNoBg", Image.Logo.appleNoBg),
            ("appleWithBg", Image.Logo.appleWithBg),
            ("kakaoNoBg", Image.Logo.kakaoNoBg),
            ("kakaoWithBg", Image.Logo.kakaoWithBg),
        ]),
        Family(name: "Play", members: [
            ("dark34", Image.Play.dark34),
            ("default24", Image.Play.default24),
            ("green34", Image.Play.green34),
        ]),
        Family(name: "Plus", members: [
            ("dark16", Image.Plus.dark16),
            ("dark20", Image.Plus.dark20),
            ("dark24", Image.Plus.dark24),
            ("default16", Image.Plus.default16),
            ("default20", Image.Plus.default20),
            ("default24", Image.Plus.default24),
            ("disabled16", Image.Plus.disabled16),
            ("disabled20", Image.Plus.disabled20),
            ("disabled24", Image.Plus.disabled24),
        ]),
        Family(name: "Profile", members: [
            ("default", Image.Profile.default),
            ("disabled", Image.Profile.disabled),
        ]),
        Family(name: "Q", members: [
            ("default", Image.Q.default),
        ]),
        Family(name: "Right", members: [
            ("dark24", Image.Right.dark24),
            ("default24", Image.Right.default24),
            ("disabled24", Image.Right.disabled24),
            ("grey16", Image.Right.grey16),
            ("white16", Image.Right.white16),
        ]),
        Family(name: "Script", members: [
            ("dark20", Image.Script.dark20),
            ("dark24", Image.Script.dark24),
            ("default24", Image.Script.default24),
        ]),
        Family(name: "SkipL", members: [
            ("dark20", Image.SkipL.dark20),
            ("dark34", Image.SkipL.dark34),
        ]),
        Family(name: "SkipR", members: [
            ("dark20", Image.SkipR.dark20),
            ("dark34", Image.SkipR.dark34),
        ]),
        Family(name: "Stop", members: [
            ("dark34", Image.Stop.dark34),
            ("default24", Image.Stop.default24),
            ("green34", Image.Stop.green34),
        ]),
        Family(name: "Success", members: [
            ("default16", Image.Success.default16),
            ("default20", Image.Success.default20),
            ("green16", Image.Success.green16),
            ("green20", Image.Success.green20),
        ]),
        Family(name: "Timer", members: [
            ("default16", Image.Timer.default16),
            ("default24", Image.Timer.default24),
            ("disabled16", Image.Timer.disabled16),
            ("disabled24", Image.Timer.disabled24),
        ]),
        Family(name: "Undo", members: [
            ("dark", Image.Undo.dark),
            ("default", Image.Undo.default),
            ("disabled", Image.Undo.disabled),
        ]),
        Family(name: "Up", members: [
            ("dark", Image.Up.dark),
            ("default", Image.Up.default),
            ("disabled", Image.Up.disabled),
        ]),
        Family(name: "Upload", members: [
            ("default", Image.Upload.default),
        ]),
        Family(name: "Video", members: [
            ("default16", Image.Video.default16),
            ("default24", Image.Video.default24),
            ("disabled24", Image.Video.disabled24),
            ("white24", Image.Video.white24),
        ]),
    ]

    var body: some View {
        CatalogPage("이미지") {
            ForEach(families) { family in
                CatalogGroup("Image.\(family.name)") {
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: .ds(.p8)), count: 3), spacing: .ds(.p8)) {
                        ForEach(family.members, id: \.name) { member in
                            VStack(spacing: .ds(.p4)) {
                                member.image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .padding(.ds(.p8))
                                    .frame(maxWidth: .infinity)
                                    .background(tile(for: member.name))
                                Text(member.name)
                                    .dsTypography(.body9)
                                    .foregroundStyle(Color.GrayScale.g700)
                            }
                        }
                    }
                }
            }
        }
    }

    private func tile(for member: String) -> Color {
        member.hasPrefix("white") ? Color.HilitBlack.b900 : Color.GrayScale.g50
    }
}

#Preview {
    NavigationStack { CatalogImageView() }
}
