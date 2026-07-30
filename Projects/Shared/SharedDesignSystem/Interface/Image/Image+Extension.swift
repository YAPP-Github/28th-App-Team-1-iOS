//
//  Image+Extension.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/23.
//

import SwiftUI

/// Tuist 가 Assets.xcassets 를 스캔해 만드는 접근자(`Derived/Sources/TuistAssets+…`)의 축약.
/// 에셋을 지우거나 이름을 바꾸면 여기서 **컴파일이 깨진다** — 문자열 로드였을 땐 런타임에야 드러났다.
private typealias Asset = SharedDesignSystemInterfaceAsset

// @lat: [[architecture#디자인 시스템]]
// 이미지 토큰 — 아이콘은 Figma 아이콘 패밀리별 enum(`Cancel`·`Plus`…), 일러스트는 `Img`.
// 멤버 이름은 «색변형 + 크기» 다 (`Cancel.white24`). 크기는 그 패밀리에 여러 개일 때만 붙는다 —
// 하나뿐이면 생략한다(`Left.default`). 에셋은 색이 구워진 채로 쓰고 틴트하지 않는다.
public extension Image {

    enum Ai {
        public static var green16: Image { Asset.Assets.aiGreen16.swiftUIImage }
        public static var green24: Image { Asset.Assets.aiGreen24.swiftUIImage }
    }

    enum Cancel {
        public static var default24: Image { Asset.Assets.cancelDefault24.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.cancelDisabled24.swiftUIImage }
        public static var white16: Image { Asset.Assets.cancelWhite16.swiftUIImage }
        public static var white20: Image { Asset.Assets.cancelWhite20.swiftUIImage }
        public static var white24: Image { Asset.Assets.cancelWhite24.swiftUIImage }
    }

    enum CancelMini {
        public static var black16: Image { Asset.Assets.cancelMiniBlack16.swiftUIImage }
        public static var default24: Image { Asset.Assets.cancelMiniDefault24.swiftUIImage }
        public static var gray16: Image { Asset.Assets.cancelMiniGray16.swiftUIImage }
        public static var gray24: Image { Asset.Assets.cancelMiniGray24.swiftUIImage }
    }

    /// 체크박스 안 체크 표시 12×11 — Figma «Checkbox»(3768:16630) 내부 벡터라 아이콘 시트에 없다.
    /// green = 켜짐(b800 판 위) / gray = 꺼짐(흰 판 위 유령 체크).
    enum Check {
        public static var gray: Image { Asset.Assets.checkGray.swiftUIImage }
        public static var green: Image { Asset.Assets.checkGreen.swiftUIImage }
    }

    enum Coupon {
        public static var `default`: Image { Asset.Assets.couponDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.couponDisabled.swiftUIImage }
    }

    enum Down {
        public static var `default`: Image { Asset.Assets.downDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.downDisabled.swiftUIImage }
        public static var white: Image { Asset.Assets.downWhite.swiftUIImage }
    }

    enum Edit {
        public static var default16: Image { Asset.Assets.editDefault16.swiftUIImage }
        public static var default24: Image { Asset.Assets.editDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.editDisabled16.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.editDisabled24.swiftUIImage }
    }

    enum Expand {
        public static var default24: Image { Asset.Assets.expandDefault24.swiftUIImage }
        public static var default30: Image { Asset.Assets.expandDefault30.swiftUIImage }
    }

    enum Feedback {
        public static var body20: Image { Asset.Assets.feedbackBody20.swiftUIImage }
        public static var body24: Image { Asset.Assets.feedbackBody24.swiftUIImage }
        public static var body28: Image { Asset.Assets.feedbackBody28.swiftUIImage }
        public static var eyes20: Image { Asset.Assets.feedbackEyes20.swiftUIImage }
        public static var eyes24: Image { Asset.Assets.feedbackEyes24.swiftUIImage }
        public static var eyes28: Image { Asset.Assets.feedbackEyes28.swiftUIImage }
        public static var face20: Image { Asset.Assets.feedbackFace20.swiftUIImage }
        public static var face24: Image { Asset.Assets.feedbackFace24.swiftUIImage }
        public static var face28: Image { Asset.Assets.feedbackFace28.swiftUIImage }
        public static var hand20: Image { Asset.Assets.feedbackHand20.swiftUIImage }
        public static var hand24: Image { Asset.Assets.feedbackHand24.swiftUIImage }
        public static var hand28: Image { Asset.Assets.feedbackHand28.swiftUIImage }
        public static var voice20: Image { Asset.Assets.feedbackVoice20.swiftUIImage }
        public static var voice24: Image { Asset.Assets.feedbackVoice24.swiftUIImage }
        public static var voice28: Image { Asset.Assets.feedbackVoice28.swiftUIImage }
    }

    enum File {
        public static var default16: Image { Asset.Assets.fileDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.fileDefault20.swiftUIImage }
        public static var default24: Image { Asset.Assets.fileDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.fileDisabled16.swiftUIImage }
        public static var disabled20: Image { Asset.Assets.fileDisabled20.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.fileDisabled24.swiftUIImage }
        public static var green20: Image { Asset.Assets.fileGreen20.swiftUIImage }
        public static var green36: Image { Asset.Assets.fileGreen36.swiftUIImage }
        public static var white16: Image { Asset.Assets.fileWhite16.swiftUIImage }
        public static var white20: Image { Asset.Assets.fileWhite20.swiftUIImage }
        public static var white24: Image { Asset.Assets.fileWhite24.swiftUIImage }
        public static var white36: Image { Asset.Assets.fileWhite36.swiftUIImage }
    }

    enum HilitAnalyze {
        public static var aiSparkle: Image { Asset.Assets.hilitAnalyzeAiSparkle.swiftUIImage }
        public static var problem: Image { Asset.Assets.hilitAnalyzeProblem.swiftUIImage }
        public static var question: Image { Asset.Assets.hilitAnalyzeQuestion.swiftUIImage }
        public static var success: Image { Asset.Assets.hilitAnalyzeSuccess.swiftUIImage }
    }

    enum Img {
        public static var book: Image { Asset.Assets.imgBook.swiftUIImage }
        public static var feedback: Image { Asset.Assets.imgFeedback.swiftUIImage }
        public static var finish: Image { Asset.Assets.imgFinish.swiftUIImage }
        public static var link: Image { Asset.Assets.imgLink.swiftUIImage }
        public static var micError: Image { Asset.Assets.imgMicError.swiftUIImage }
        public static var networkError: Image { Asset.Assets.imgNetworkError.swiftUIImage }
        public static var oppEllipsis: Image { Asset.Assets.imgOppEllipsis.swiftUIImage }
        public static var oppO: Image { Asset.Assets.imgOppO.swiftUIImage }
        public static var oppX: Image { Asset.Assets.imgOppX.swiftUIImage }
        public static var person: Image { Asset.Assets.imgPerson.swiftUIImage }
        public static var reportEmpty: Image { Asset.Assets.imgReportEmpty.swiftUIImage }
        public static var success: Image { Asset.Assets.imgSuccess.swiftUIImage }
        public static var talk: Image { Asset.Assets.imgTalk.swiftUIImage }
        public static var tooltipTail: Image { Asset.Assets.imgTooltipTail.swiftUIImage }
    }

    enum Info {
        public static var `default`: Image { Asset.Assets.infoDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.infoDisabled.swiftUIImage }
        /// 빨간 안내 아이콘 — Figma 는 `info-field/red` 안에서 인스턴스에 e500 을 덮어썼을 뿐
        /// 아이콘 시트에 이름 붙은 변형이 없다. 틴트가 금지라 `default` 와 같은 도형을
        /// e500 으로 다시 칠한 에셋으로 둔다(`Issue.error*` 와 같은 방식).
        public static var error: Image { Asset.Assets.infoError.swiftUIImage }
    }

    enum Issue {
        public static var default16: Image { Asset.Assets.issueDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.issueDefault20.swiftUIImage }
        public static var default24: Image { Asset.Assets.issueDefault24.swiftUIImage }
        public static var error16: Image { Asset.Assets.issueError16.swiftUIImage }
        public static var error20: Image { Asset.Assets.issueError20.swiftUIImage }
        public static var error24: Image { Asset.Assets.issueError24.swiftUIImage }
    }

    enum Left {
        public static var `default`: Image { Asset.Assets.leftDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.leftDisabled.swiftUIImage }
        public static var white: Image { Asset.Assets.leftWhite.swiftUIImage }
    }

    enum Loading {
        public static var black24: Image { Asset.Assets.loadingBlack24.swiftUIImage }
        public static var gray24: Image { Asset.Assets.loadingGray24.swiftUIImage }
        public static var ingBlack16: Image { Asset.Assets.loadingIngBlack16.swiftUIImage }
        public static var ingGray16: Image { Asset.Assets.loadingIngGray16.swiftUIImage }
        public static var ingWhite16: Image { Asset.Assets.loadingIngWhite16.swiftUIImage }
        public static var waitBlack16: Image { Asset.Assets.loadingWaitBlack16.swiftUIImage }
        public static var waitGray16: Image { Asset.Assets.loadingWaitGray16.swiftUIImage }
        public static var waitWhite16: Image { Asset.Assets.loadingWaitWhite16.swiftUIImage }
        public static var white24: Image { Asset.Assets.loadingWhite24.swiftUIImage }
    }

    enum Logo {
        public static var appleNoBg: Image { Asset.Assets.logoAppleNoBg.swiftUIImage }
        public static var appleWithBg: Image { Asset.Assets.logoAppleWithBg.swiftUIImage }
        public static var appleWithBg24: Image { Asset.Assets.logoAppleWithBg24.swiftUIImage }
        /// Hilit 워드마크 57×24 — 내비바 logo 변형 (Figma 3768:5296)
        public static var hilit: Image { Asset.Assets.logoHilit.swiftUIImage }
        public static var kakaoNoBg: Image { Asset.Assets.logoKakaoNoBg.swiftUIImage }
        public static var kakaoWithBg: Image { Asset.Assets.logoKakaoWithBg.swiftUIImage }
        public static var kakaoWithBg24: Image { Asset.Assets.logoKakaoWithBg24.swiftUIImage }
    }

    enum Pause {
        public static var default24: Image { Asset.Assets.pauseDefault24.swiftUIImage }
        public static var green34: Image { Asset.Assets.pauseGreen34.swiftUIImage }
        public static var white34: Image { Asset.Assets.pauseWhite34.swiftUIImage }
    }

    enum Play {
        public static var default24: Image { Asset.Assets.playDefault24.swiftUIImage }
        public static var green34: Image { Asset.Assets.playGreen34.swiftUIImage }
        public static var white34: Image { Asset.Assets.playWhite34.swiftUIImage }
    }

    enum Plus {
        public static var default16: Image { Asset.Assets.plusDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.plusDefault20.swiftUIImage }
        public static var default24: Image { Asset.Assets.plusDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.plusDisabled16.swiftUIImage }
        public static var disabled20: Image { Asset.Assets.plusDisabled20.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.plusDisabled24.swiftUIImage }
        public static var white16: Image { Asset.Assets.plusWhite16.swiftUIImage }
        public static var white20: Image { Asset.Assets.plusWhite20.swiftUIImage }
        public static var white24: Image { Asset.Assets.plusWhite24.swiftUIImage }
    }

    enum Profile {
        public static var `default`: Image { Asset.Assets.profileDefault.swiftUIImage }
        public static var defaultAlt: Image { Asset.Assets.profileDefaultAlt.swiftUIImage }
        public static var disabled: Image { Asset.Assets.profileDisabled.swiftUIImage }
    }

    enum Q {
        public static var `default`: Image { Asset.Assets.qDefault.swiftUIImage }
    }

    enum Right {
        public static var default24: Image { Asset.Assets.rightDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.rightDisabled16.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.rightDisabled24.swiftUIImage }
        public static var gray16: Image { Asset.Assets.rightGray16.swiftUIImage }
        public static var white16: Image { Asset.Assets.rightWhite16.swiftUIImage }
        public static var white24: Image { Asset.Assets.rightWhite24.swiftUIImage }
    }

    enum Script {
        public static var default24: Image { Asset.Assets.scriptDefault24.swiftUIImage }
        public static var white20: Image { Asset.Assets.scriptWhite20.swiftUIImage }
        public static var white24: Image { Asset.Assets.scriptWhite24.swiftUIImage }
    }

    enum SkipL {
        public static var white20: Image { Asset.Assets.skipLWhite20.swiftUIImage }
        public static var white34: Image { Asset.Assets.skipLWhite34.swiftUIImage }
    }

    enum SkipR {
        public static var white20: Image { Asset.Assets.skipRWhite20.swiftUIImage }
        public static var white34: Image { Asset.Assets.skipRWhite34.swiftUIImage }
    }

    enum Success {
        public static var black16: Image { Asset.Assets.successBlack16.swiftUIImage }
        public static var black24: Image { Asset.Assets.successBlack24.swiftUIImage }
        public static var default16: Image { Asset.Assets.successDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.successDefault20.swiftUIImage }
        public static var gray16: Image { Asset.Assets.successGray16.swiftUIImage }
        public static var gray24: Image { Asset.Assets.successGray24.swiftUIImage }
        public static var green16: Image { Asset.Assets.successGreen16.swiftUIImage }
        public static var green20: Image { Asset.Assets.successGreen20.swiftUIImage }
    }

    enum Timer {
        public static var default16: Image { Asset.Assets.timerDefault16.swiftUIImage }
        public static var default24: Image { Asset.Assets.timerDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.timerDisabled16.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.timerDisabled24.swiftUIImage }
        public static var green16: Image { Asset.Assets.timerGreen16.swiftUIImage }
        public static var green24: Image { Asset.Assets.timerGreen24.swiftUIImage }
    }

    enum Undo {
        public static var `default`: Image { Asset.Assets.undoDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.undoDisabled.swiftUIImage }
        public static var white: Image { Asset.Assets.undoWhite.swiftUIImage }
    }

    enum Up {
        public static var `default`: Image { Asset.Assets.upDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.upDisabled.swiftUIImage }
        public static var white: Image { Asset.Assets.upWhite.swiftUIImage }
    }

    enum Upload {
        public static var `default`: Image { Asset.Assets.uploadDefault.swiftUIImage }
    }

    enum Video {
        public static var default16: Image { Asset.Assets.videoDefault16.swiftUIImage }
        public static var default24: Image { Asset.Assets.videoDefault24.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.videoDisabled24.swiftUIImage }
        public static var white16: Image { Asset.Assets.videoWhite16.swiftUIImage }
        public static var white24: Image { Asset.Assets.videoWhite24.swiftUIImage }
    }
}
