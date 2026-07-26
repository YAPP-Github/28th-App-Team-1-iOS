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
// 멤버 이름은 «색변형 + 크기» 다 (`Cancel.dark24`). 크기는 그 패밀리에 여러 개일 때만 붙는다 —
// 하나뿐이면 생략한다(`Left.default`). 에셋은 색이 구워진 채로 쓰고 틴트하지 않는다.
public extension Image {

    enum Ai {
        public static var green: Image { Asset.Assets.aiGreen.swiftUIImage }
    }

    enum Cancel {
        public static var dark16: Image { Asset.Assets.cancelDark16.swiftUIImage }
        public static var dark20: Image { Asset.Assets.cancelDark20.swiftUIImage }
        public static var dark24: Image { Asset.Assets.cancelDark24.swiftUIImage }
        public static var default24: Image { Asset.Assets.cancelDefault24.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.cancelDisabled24.swiftUIImage }
    }

    enum CancelMini {
        public static var black16: Image { Asset.Assets.cancelMiniBlack16.swiftUIImage }
        public static var black24: Image { Asset.Assets.cancelMiniBlack24.swiftUIImage }
        public static var grey16: Image { Asset.Assets.cancelMiniGrey16.swiftUIImage }
        public static var grey24: Image { Asset.Assets.cancelMiniGrey24.swiftUIImage }
    }

    enum Coupon {
        public static var `default`: Image { Asset.Assets.couponDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.couponDisabled.swiftUIImage }
    }

    enum Down {
        public static var dark: Image { Asset.Assets.downDark.swiftUIImage }
        public static var `default`: Image { Asset.Assets.downDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.downDisabled.swiftUIImage }
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
        public static var dark16: Image { Asset.Assets.fileDark16.swiftUIImage }
        public static var dark20: Image { Asset.Assets.fileDark20.swiftUIImage }
        public static var dark24: Image { Asset.Assets.fileDark24.swiftUIImage }
        public static var default16: Image { Asset.Assets.fileDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.fileDefault20.swiftUIImage }
        public static var default24: Image { Asset.Assets.fileDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.fileDisabled16.swiftUIImage }
        public static var disabled20: Image { Asset.Assets.fileDisabled20.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.fileDisabled24.swiftUIImage }
    }

    enum Ic {
        public static var cancelMini: Image { Asset.Assets.icCancelMini.swiftUIImage }
        public static var cancelSmall: Image { Asset.Assets.icCancelSmall.swiftUIImage }
        public static var close: Image { Asset.Assets.icClose.swiftUIImage }
        public static var error: Image { Asset.Assets.icError.swiftUIImage }
        public static var info: Image { Asset.Assets.icInfo.swiftUIImage }
        public static var success: Image { Asset.Assets.icSuccess.swiftUIImage }
        public static var upload: Image { Asset.Assets.icUpload.swiftUIImage }
    }

    enum Img {
        public static var book: Image { Asset.Assets.imgBook.swiftUIImage }
        public static var link: Image { Asset.Assets.imgLink.swiftUIImage }
        public static var micError: Image { Asset.Assets.imgMicError.swiftUIImage }
        public static var networkError: Image { Asset.Assets.imgNetworkError.swiftUIImage }
        public static var tooltipTail: Image { Asset.Assets.imgTooltipTail.swiftUIImage }
    }

    enum Info {
        public static var `default`: Image { Asset.Assets.infoDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.infoDisabled.swiftUIImage }
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
        public static var dark: Image { Asset.Assets.leftDark.swiftUIImage }
        public static var `default`: Image { Asset.Assets.leftDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.leftDisabled.swiftUIImage }
    }

    enum Loading {
        public static var dark24: Image { Asset.Assets.loadingDark24.swiftUIImage }
        public static var ingDark16: Image { Asset.Assets.loadingIngDark16.swiftUIImage }
        public static var ingGreen24: Image { Asset.Assets.loadingIngGreen24.swiftUIImage }
        public static var ingGrey16: Image { Asset.Assets.loadingIngGrey16.swiftUIImage }
        public static var ingWhite16: Image { Asset.Assets.loadingIngWhite16.swiftUIImage }
        public static var successDark16: Image { Asset.Assets.loadingSuccessDark16.swiftUIImage }
        public static var successDark24: Image { Asset.Assets.loadingSuccessDark24.swiftUIImage }
        public static var successGreen24: Image { Asset.Assets.loadingSuccessGreen24.swiftUIImage }
        public static var successGrey16: Image { Asset.Assets.loadingSuccessGrey16.swiftUIImage }
        public static var waitDark16: Image { Asset.Assets.loadingWaitDark16.swiftUIImage }
        public static var waitGrey16: Image { Asset.Assets.loadingWaitGrey16.swiftUIImage }
        public static var waitWhite16: Image { Asset.Assets.loadingWaitWhite16.swiftUIImage }
        public static var white24: Image { Asset.Assets.loadingWhite24.swiftUIImage }
    }

    enum Logo {
        public static var appleNoBg: Image { Asset.Assets.logoAppleNoBg.swiftUIImage }
        public static var appleWithBg: Image { Asset.Assets.logoAppleWithBg.swiftUIImage }
        public static var kakaoNoBg: Image { Asset.Assets.logoKakaoNoBg.swiftUIImage }
        public static var kakaoWithBg: Image { Asset.Assets.logoKakaoWithBg.swiftUIImage }
    }

    enum Play {
        public static var dark34: Image { Asset.Assets.playDark34.swiftUIImage }
        public static var default24: Image { Asset.Assets.playDefault24.swiftUIImage }
        public static var green34: Image { Asset.Assets.playGreen34.swiftUIImage }
    }

    enum Plus {
        public static var dark16: Image { Asset.Assets.plusDark16.swiftUIImage }
        public static var dark20: Image { Asset.Assets.plusDark20.swiftUIImage }
        public static var dark24: Image { Asset.Assets.plusDark24.swiftUIImage }
        public static var default16: Image { Asset.Assets.plusDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.plusDefault20.swiftUIImage }
        public static var default24: Image { Asset.Assets.plusDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.plusDisabled16.swiftUIImage }
        public static var disabled20: Image { Asset.Assets.plusDisabled20.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.plusDisabled24.swiftUIImage }
    }

    enum Profile {
        public static var `default`: Image { Asset.Assets.profileDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.profileDisabled.swiftUIImage }
    }

    enum Q {
        public static var `default`: Image { Asset.Assets.qDefault.swiftUIImage }
    }

    enum Right {
        public static var dark24: Image { Asset.Assets.rightDark24.swiftUIImage }
        public static var default24: Image { Asset.Assets.rightDefault24.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.rightDisabled24.swiftUIImage }
        public static var grey16: Image { Asset.Assets.rightGrey16.swiftUIImage }
        public static var white16: Image { Asset.Assets.rightWhite16.swiftUIImage }
    }

    enum Script {
        public static var dark20: Image { Asset.Assets.scriptDark20.swiftUIImage }
        public static var dark24: Image { Asset.Assets.scriptDark24.swiftUIImage }
        public static var default24: Image { Asset.Assets.scriptDefault24.swiftUIImage }
    }

    enum SkipL {
        public static var dark20: Image { Asset.Assets.skipLDark20.swiftUIImage }
        public static var dark34: Image { Asset.Assets.skipLDark34.swiftUIImage }
    }

    enum SkipR {
        public static var dark20: Image { Asset.Assets.skipRDark20.swiftUIImage }
        public static var dark34: Image { Asset.Assets.skipRDark34.swiftUIImage }
    }

    enum Stop {
        public static var dark34: Image { Asset.Assets.stopDark34.swiftUIImage }
        public static var default24: Image { Asset.Assets.stopDefault24.swiftUIImage }
        public static var green34: Image { Asset.Assets.stopGreen34.swiftUIImage }
    }

    enum Success {
        public static var default16: Image { Asset.Assets.successDefault16.swiftUIImage }
        public static var default20: Image { Asset.Assets.successDefault20.swiftUIImage }
        public static var green16: Image { Asset.Assets.successGreen16.swiftUIImage }
        public static var green20: Image { Asset.Assets.successGreen20.swiftUIImage }
    }

    enum Timer {
        public static var default16: Image { Asset.Assets.timerDefault16.swiftUIImage }
        public static var default24: Image { Asset.Assets.timerDefault24.swiftUIImage }
        public static var disabled16: Image { Asset.Assets.timerDisabled16.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.timerDisabled24.swiftUIImage }
    }

    enum Undo {
        public static var dark: Image { Asset.Assets.undoDark.swiftUIImage }
        public static var `default`: Image { Asset.Assets.undoDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.undoDisabled.swiftUIImage }
    }

    enum Up {
        public static var dark: Image { Asset.Assets.upDark.swiftUIImage }
        public static var `default`: Image { Asset.Assets.upDefault.swiftUIImage }
        public static var disabled: Image { Asset.Assets.upDisabled.swiftUIImage }
    }

    enum Upload {
        public static var `default`: Image { Asset.Assets.uploadDefault.swiftUIImage }
    }

    enum Video {
        public static var default16: Image { Asset.Assets.videoDefault16.swiftUIImage }
        public static var default24: Image { Asset.Assets.videoDefault24.swiftUIImage }
        public static var disabled24: Image { Asset.Assets.videoDisabled24.swiftUIImage }
        public static var white24: Image { Asset.Assets.videoWhite24.swiftUIImage }
    }
}
