//
//  CatalogImageView.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 이미지 토큰 전체. `static var` 묶음이라 순회가 안 돼 손으로 열거한다
/// (목록은 `Image+Extension.swift` 에서 기계적으로 뽑았다 — 에셋을 추가하면 여기도 한 줄 추가).
///
/// 실제 크기는 토큰 이름에 있다(`default16`·`white24`) — 타일에서는 비교를 위해 같은 칸에 맞춰 그린다.
/// 흰 아이콘(`white…`)은 밝은 배경에서 안 보여 타일 배경을 어둡게 깐다. 틴트는 걸지 않는다(색은 에셋에 구움).
struct CatalogImageView: View {
    private struct Family: Identifiable {
        let name: String
        let members: [(name: String, image: Image)]
        var id: String { name }
    }

    private let families: [Family] = [
        Family(name: "Ai", members: [
            ("green16", Image.Ai.green16),
            ("green24", Image.Ai.green24),
        ]),
        Family(name: "Cancel", members: [
            ("default24", Image.Cancel.default24),
            ("disabled24", Image.Cancel.disabled24),
            ("white16", Image.Cancel.white16),
            ("white20", Image.Cancel.white20),
            ("white24", Image.Cancel.white24),
        ]),
        Family(name: "CancelMini", members: [
            ("black16", Image.CancelMini.black16),
            ("default24", Image.CancelMini.default24),
            ("gray16", Image.CancelMini.gray16),
            ("gray24", Image.CancelMini.gray24),
        ]),
        Family(name: "Coupon", members: [
            ("default", Image.Coupon.`default`),
            ("disabled", Image.Coupon.disabled),
        ]),
        Family(name: "Down", members: [
            ("default", Image.Down.`default`),
            ("disabled", Image.Down.disabled),
            ("white", Image.Down.white),
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
            ("default16", Image.File.default16),
            ("default20", Image.File.default20),
            ("default24", Image.File.default24),
            ("disabled16", Image.File.disabled16),
            ("disabled20", Image.File.disabled20),
            ("disabled24", Image.File.disabled24),
            ("green20", Image.File.green20),
            ("green36", Image.File.green36),
            ("white16", Image.File.white16),
            ("white20", Image.File.white20),
            ("white24", Image.File.white24),
            ("white36", Image.File.white36),
        ]),
        Family(name: "HilitAnalyze", members: [
            ("aiSparkle", Image.HilitAnalyze.aiSparkle),
            ("problem", Image.HilitAnalyze.problem),
            ("success", Image.HilitAnalyze.success),
        ]),
        Family(name: "Img", members: [
            ("book", Image.Img.book),
            ("feedback", Image.Img.feedback),
            ("finish", Image.Img.finish),
            ("link", Image.Img.link),
            ("micError", Image.Img.micError),
            ("networkError", Image.Img.networkError),
            ("oppEllipsis", Image.Img.oppEllipsis),
            ("oppO", Image.Img.oppO),
            ("oppX", Image.Img.oppX),
            ("person", Image.Img.person),
            ("reportEmpty", Image.Img.reportEmpty),
            ("success", Image.Img.success),
            ("talk", Image.Img.talk),
            ("tooltipTail", Image.Img.tooltipTail),
        ]),
        Family(name: "Info", members: [
            ("default", Image.Info.`default`),
            ("disabled", Image.Info.disabled),
            ("error", Image.Info.error),
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
            ("default", Image.Left.`default`),
            ("disabled", Image.Left.disabled),
            ("white", Image.Left.white),
        ]),
        Family(name: "Loading", members: [
            ("black24", Image.Loading.black24),
            ("gray24", Image.Loading.gray24),
            ("ingBlack16", Image.Loading.ingBlack16),
            ("ingGray16", Image.Loading.ingGray16),
            ("ingWhite16", Image.Loading.ingWhite16),
            ("waitBlack16", Image.Loading.waitBlack16),
            ("waitGray16", Image.Loading.waitGray16),
            ("waitWhite16", Image.Loading.waitWhite16),
            ("white24", Image.Loading.white24),
        ]),
        Family(name: "Logo", members: [
            ("appleNoBg", Image.Logo.appleNoBg),
            ("appleWithBg", Image.Logo.appleWithBg),
            ("appleWithBg24", Image.Logo.appleWithBg24),
            ("kakaoNoBg", Image.Logo.kakaoNoBg),
            ("kakaoWithBg", Image.Logo.kakaoWithBg),
            ("kakaoWithBg24", Image.Logo.kakaoWithBg24),
        ]),
        Family(name: "Pause", members: [
            ("default24", Image.Pause.default24),
            ("green34", Image.Pause.green34),
            ("white34", Image.Pause.white34),
        ]),
        Family(name: "Play", members: [
            ("default24", Image.Play.default24),
            ("green34", Image.Play.green34),
            ("white34", Image.Play.white34),
        ]),
        Family(name: "Plus", members: [
            ("default16", Image.Plus.default16),
            ("default20", Image.Plus.default20),
            ("default24", Image.Plus.default24),
            ("disabled16", Image.Plus.disabled16),
            ("disabled20", Image.Plus.disabled20),
            ("disabled24", Image.Plus.disabled24),
            ("white16", Image.Plus.white16),
            ("white20", Image.Plus.white20),
            ("white24", Image.Plus.white24),
        ]),
        Family(name: "Profile", members: [
            ("default", Image.Profile.`default`),
            ("defaultAlt", Image.Profile.defaultAlt),
            ("disabled", Image.Profile.disabled),
        ]),
        Family(name: "Q", members: [
            ("default", Image.Q.`default`),
        ]),
        Family(name: "Right", members: [
            ("default24", Image.Right.default24),
            ("disabled16", Image.Right.disabled16),
            ("disabled24", Image.Right.disabled24),
            ("gray16", Image.Right.gray16),
            ("white16", Image.Right.white16),
            ("white24", Image.Right.white24),
        ]),
        Family(name: "Script", members: [
            ("default24", Image.Script.default24),
            ("white20", Image.Script.white20),
            ("white24", Image.Script.white24),
        ]),
        Family(name: "SkipL", members: [
            ("white20", Image.SkipL.white20),
            ("white34", Image.SkipL.white34),
        ]),
        Family(name: "SkipR", members: [
            ("white20", Image.SkipR.white20),
            ("white34", Image.SkipR.white34),
        ]),
        Family(name: "Success", members: [
            ("black16", Image.Success.black16),
            ("black24", Image.Success.black24),
            ("default16", Image.Success.default16),
            ("default20", Image.Success.default20),
            ("gray16", Image.Success.gray16),
            ("gray24", Image.Success.gray24),
            ("green16", Image.Success.green16),
            ("green20", Image.Success.green20),
        ]),
        Family(name: "Timer", members: [
            ("default16", Image.Timer.default16),
            ("default24", Image.Timer.default24),
            ("disabled16", Image.Timer.disabled16),
            ("disabled24", Image.Timer.disabled24),
            ("green16", Image.Timer.green16),
            ("green24", Image.Timer.green24),
        ]),
        Family(name: "Undo", members: [
            ("default", Image.Undo.`default`),
            ("disabled", Image.Undo.disabled),
            ("white", Image.Undo.white),
        ]),
        Family(name: "Up", members: [
            ("default", Image.Up.`default`),
            ("disabled", Image.Up.disabled),
            ("white", Image.Up.white),
        ]),
        Family(name: "Upload", members: [
            ("default", Image.Upload.`default`),
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
        member.lowercased().contains("white") ? Color.HilitBlack.b900 : Color.GrayScale.g50
    }
}

#Preview {
    NavigationStack { CatalogImageView() }
}
