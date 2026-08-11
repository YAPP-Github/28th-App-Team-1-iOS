import Foundation

/// 프로젝트에 존재하는 모든 모듈의 단일 레지스트리.
/// 새 모듈 추가 시 반드시 이 파일의 해당 레이어 enum에 case를 등록해야 한다.
/// CaseIterable을 통해 전체 모듈 목록 순회 및 검증 자동화가 가능하다.
public enum ModulePath {
    public enum Feature: String, CaseIterable {
        case home = "Home"
        case auth = "Auth"
        case guestFeedback = "GuestFeedback"
        case onboarding = "Onboarding"
        case interview = "Interview"
        case myPage = "MyPage"
        case report = "Report"

        public static let name = "Feature"
    }

    public enum Domain: String, CaseIterable {
        case common = "Common"
        case auth = "Auth"
        case interview = "Interview"
        // 디바이스 측 IO (서버 API 아님) — 카메라·마이크 권한
        case permission = "Permission"
        // 디바이스 측 IO — 카메라 프리뷰·A/V 캡처 (RecordingClient)
        case recording = "Recording"
        // 디바이스 측 IO — 마이크 캡처·발화 감지, 추후 TTS/STT (SpeechClient)
        case speech = "Speech"
        // D14 서버 API 도메인 미러링 — [[api]]
        case appVersion = "AppVersion"
        case consent = "Consent"
        case jd = "JD"
        case job = "Job"
        case portfolio = "Portfolio"
        case user = "User"
        case interviewReport = "InterviewReport"
        case feedbackShare = "FeedbackShare"
        case guestFeedback = "GuestFeedback"

        public static let name = "Domain"
    }

    public enum Core: String, CaseIterable {
        case common = "Common"
        case network = "Network"

        public static let name = "Core"
    }

    public enum Shared: String, CaseIterable {
        case designSystem = "DesignSystem"

        public static let name = "Shared"
    }
}
