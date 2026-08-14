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

/// 축별 질문·4단계 척도 카피 — Figma «Part4 지인피드백 / 질문 케이스 베리에이션»(802:9185) 5축 확정 문구.
/// 다섯 축 전부 시안이 나와 잠정 문구가 사라졌고, 질문에서 요청자 이름이 빠졌다(주어가 영상 속 인물로 자명).
enum AxisScaleCopy {
    /// index 0 → level 1(긍정) … index 3 → level 4(아쉬움).
    /// 미확정 축 코드가 서버에서 오면 축 이름만으로 성립하는 중립 문구로 떨어진다.
    static func labels(for code: String) -> [String] {
        switch code {
        case "EXPRESSION": ["안정됨", "꽤 안정됨", "가끔 굳음", "자주 굳음"]        // Figma «표정» 802:8885
        case "GAZE": ["잘 맞춤", "꽤 맞춤", "가끔 피함", "자주 피함"]              // Figma «시선» 802:8814
        case "GESTURE": ["잘 어울림", "꽤 어울림", "가끔 산만", "매우 산만"]     // Figma «손동작» 802:9027
        case "POSTURE": ["반듯함", "꽤 반듯함", "가끔 산만", "매우 산만"]     // Figma «자세» 802:8956
        case "VOICE": ["잘 들림", "꽤 들림", "꽤 안들림", "안들림"]          // Figma «목소리» 802:9098
        default: ["좋았어요", "괜찮았어요", "조금 아쉬움", "많이 아쉬움"]
        }
    }

    static func headline(for axis: AttitudeAxis) -> String {
        switch axis.code {
        case "EXPRESSION": return "표정이 안정되어 보이나요?"
        case "GAZE": return "눈을 잘 마주치나요?"
        case "GESTURE": return "손동작이 말과 잘 어울리나요?"
        case "POSTURE": return "자세를 잘 유지하나요?"
        case "VOICE": return "목소리가 선명하게 들리나요?"
        default: return "\(axis.displayName), 어땠나요?"
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
