//
//  TranscriptTimestamp.swift
//  DomainInterviewReportInterface
//
//  Created by EunSeo on 26/07/29.
//

import Foundation

/// 대본의 시간축. 서버는 같은 발화를 **두 자리**에 담아 내려준다 —
/// 카드 안의 `scriptSegments`(그 질문 턴에 속한 문장들)와 응답 최상위 `script`(세션 전체 타임라인).
///
/// 둘의 모양이 같아서 한 타입으로 받는다. 다른 점은 문자 인덱스뿐이다 — 카드 쪽은 `transcript`
/// 문자열 기준 오프셋을 함께 주지만(하이라이트와 같은 좌표계), 전체 타임라인 쪽은 붙일 대본이 없어 비어 온다.

/// 발화 주체. 대본에 면접관 질문과 면접자 답변이 섞여 오므로 화면이 갈라 쓴다.
/// 모르는 값은 `.unknown` 으로 흡수한다 — 서버가 새 역할을 추가해도 대본이 통째로 사라지지 않게.
public enum ScriptRole: String, Decodable, Equatable, Sendable {
    case interviewer = "INTERVIEWER"
    case interviewee = "INTERVIEWEE"
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ScriptRole(rawValue: raw.uppercased()) ?? .unknown
    }
}

/// 대본 발화 하나. `startSec`/`endSec` 은 합성 영상(=녹화) 시작 기준 초라
/// 플레이어의 현재 발화 강조·진행바 칸이 그대로 쓴다.
public struct ScriptSegment: Decodable, Equatable, Sendable {
    public let role: ScriptRole
    public let text: String
    /// 카드 `transcript` 문자열 기준 시작/끝 오프셋 — 전체 타임라인(`script`)에는 없다.
    public let startIndex: Int?
    public let endIndex: Int?
    public let startSec: TimeInterval
    public let endSec: TimeInterval

    public init(
        role: ScriptRole,
        text: String,
        startIndex: Int? = nil,
        endIndex: Int? = nil,
        startSec: TimeInterval,
        endSec: TimeInterval
    ) {
        self.role = role
        self.text = text
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startSec = startSec
        self.endSec = endSec
    }

    /// 발화 길이. 서버가 뒤집힌 값을 줘도 진행바 폭이 음수가 되지 않게 0 으로 막는다.
    public var duration: TimeInterval { max(0, endSec - startSec) }

    /// 이 발화가 재생 중인지. 끝 시각은 다음 발화의 시작이라 배타로 본다.
    public func contains(_ time: TimeInterval) -> Bool {
        time >= startSec && time < endSec
    }
}
