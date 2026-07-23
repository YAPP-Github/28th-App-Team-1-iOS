//
//  GuestFeedbackSupport.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainFeedbackInterface
import Foundation

/// 게스트 텍스트 입력 규칙 (PRD §2-3) — 국문·영문·공백·숫자·특수문자 ! - ~ ? . , / [ ] < > 만 허용.
enum GuestTextRules {
    static let axisCommentLimit = 100
    static let overallLimit = 300

    private static let disallowed = "[^가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9\\s!\\-~?.,/\\[\\]<>]"

    static func sanitized(_ raw: String, limit: Int) -> String {
        let filtered = raw.replacingOccurrences(of: disallowed, with: "", options: .regularExpression)
        return String(filtered.prefix(limit))
    }
}

/// 축별 4단계 척도 카피 — GAZE·VOICE 는 Figma 최종 시안 확정 문구, 나머지 3축(표정·자세·손동작)은
/// 문구 확정 대기(PRD Part 4 §7-1)라 칩 한 줄이 유지되는 같은 길이 패턴의 잠정 문구를 쓴다.
enum AxisScaleCopy {
    /// index 0 → level 1(긍정) … index 3 → level 4(아쉬움)
    static func labels(for code: String) -> [String] {
        switch code {
        case "GAZE": ["잘 맞춤", "꽤 맞춤", "가끔 피함", "자주 피함"]     // Figma «객관식 - 선택 후» 2192:4857
        case "VOICE": ["적당함", "너무 큼", "조금 작음", "너무 작음"]     // Figma «객관식 - 선택 후» 2192:5256
        default: ["좋았어요", "괜찮았어요", "조금 아쉬움", "많이 아쉬움"]
        }
    }

    static func headline(for axis: AttitudeAxis, requesterName: String?) -> String {
        let name = requesterName ?? "지원자"
        switch axis.code {
        case "GAZE": return "\(name)님은 눈을 잘 마주치나요?"
        default: return "\(name)님의 \(axis.displayName), 어땠나요?"
        }
    }
}

extension AlertState where Action == GuestFeedbackFeature.Alert {
    static func enterFailed(message: String) -> Self {
        AlertState {
            TextState("불러오지 못했어요")
        } actions: {
            ButtonState(action: .retryEnter) { TextState("다시 시도") }
            ButtonState(role: .cancel) { TextState("닫기") }
        } message: {
            TextState(message)
        }
    }

    static func plain(message: String) -> Self {
        AlertState { TextState(message) }
    }
}

extension ConfirmationDialogState where Action == GuestFeedbackFeature.ConfirmDialog {
    static var submitConfirm: Self {
        ConfirmationDialogState(titleVisibility: .visible) {
            TextState("제출하면 다시 고칠 수 없어요")
        } actions: {
            ButtonState(action: .confirmSubmit) { TextState("제출하기") }
            ButtonState(role: .cancel) { TextState("취소") }
        } message: {
            TextState("제출 후에는 내용을 수정할 수 없어요.")
        }
    }
}
