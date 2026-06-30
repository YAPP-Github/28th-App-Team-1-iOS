import Foundation

/// 프로젝트에 존재하는 모든 모듈의 단일 레지스트리.
/// 새 모듈 추가 시 반드시 이 파일의 해당 레이어 enum에 case를 등록해야 한다.
/// CaseIterable을 통해 전체 모듈 목록 순회 및 검증 자동화가 가능하다.
public enum ModulePath {
    public enum Feature: String, CaseIterable {
        case common = "Common"
        // 추후 추가 예시: case interviewSetup = "InterviewSetup"

        public static let name = "Feature"
    }

    public enum Domain: String, CaseIterable {
        case common = "Common"
        // 추후 추가 예시: case interview = "Interview"

        public static let name = "Domain"
    }

    public enum Core: String, CaseIterable {
        case common = "Common"
        // 추후 추가 예시: case network = "Network"

        public static let name = "Core"
    }

    public enum Shared: String, CaseIterable {
        case common = "Common"
        // 추후 추가 예시: case designSystem = "DesignSystem"

        public static let name = "Shared"
    }
}
