//
//  GuestFeedbackSupport.swift
//  FeatureGuestFeedbackImplementation
//
//  Created by 서정원 on 26/07/20.
//

import ComposableArchitecture
import DomainGuestFeedbackInterface
import Foundation

// MARK: - Domain 모델 어댑터 — DomainGuestFeedback 계약(옵셔널 필드·String videoUrl)을 화면 코드 형태로.

extension AttitudeAxis: @retroactive Identifiable {
    public var id: String { code }
}

extension GuestFeedbackEntry {
    /// 서버 계약은 axes 가 옵셔널 — 화면 로직은 빈 배열로 다룬다.
    var axisList: [AttitudeAxis] { axes ?? [] }
    /// videoUrl(String) → URL. 파싱 실패는 영상 없음과 동일.
    var videoURL: URL? { videoUrl.flatMap(URL.init(string:)) }
    /// 제출 도중 정원 마감 강등 — 모델 프로퍼티가 let 이라 복사본으로 갱신.
    func closingSubmission() -> GuestFeedbackEntry {
        GuestFeedbackEntry(
            gate: gate, requesterName: requesterName, axes: axes,
            videoUrl: videoUrl, questionBoundaries: questionBoundaries, submissionOpen: false
        )
    }
}

extension GuestFeedbackError {
    /// PRD 확정 안내 문구 — 문구는 표현 관심사라 Feature 가 소유한다.
    var userMessage: String {
        switch self {
        case .shareClosed: "지금은 참여할 수 없는 링크예요."
        case .capacityFull: "이미 4분이 참여했어요."
        case .alreadySubmitted: "이미 제출하셨어요."
        case .tokenNotFound: "유효하지 않은 링크예요."
        case .invalid(let message): message
        case .networkFailure: "네트워크 연결을 확인해 주세요."
        case .serverUnavailable, .unexpected: "잠시 후 다시 시도해 주세요."
        }
    }

    /// effect catch 지점 — liveValue 가 이미 도메인 에러로 좁히므로 그 외는 unexpected.
    static func wrap(_ error: any Error) -> GuestFeedbackError {
        (error as? GuestFeedbackError) ?? .unexpected
    }
}

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
