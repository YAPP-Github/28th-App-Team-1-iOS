//
//  ConsentClient.swift
//  DomainConsentInterface
//
//  Created by EunseoKim on 26/08/01.
//

import ComposableArchitecture
import Foundation

// MARK: - Models

/// 필수 동의 상태 — 이 값 하나로 최초 동의(온보딩)인지 재동의인지 구분한다.
public enum ConsentPendingStatus: String, Decodable, Sendable {
    /// 최초 동의 필요 (신규 온보딩) — items 에 필수 5종 전체가 내려온다
    case notSubmitted = "NOT_SUBMITTED"
    /// 재동의 필요 (일부 항목 버전 변경) — 바뀐 항목만 내려온다
    case stale = "STALE"
    /// 최신 — items 는 빈 배열, 동의 화면 없이 통과
    case upToDate = "UP_TO_DATE"
}

/// 지금 동의가 필요한 항목 목록. 앱 진입 게이트 판정값을 겸한다 (docs/work/launch-routing.md).
public struct ConsentPending: Decodable, Equatable, Sendable {
    public let status: ConsentPendingStatus
    /// 프로필(이름·직군·연차) 등록 여부 — 게이트 ② 판정값. 세션 복구(Splash) 경로가
    /// login 응답 없이도 온보딩/홈을 가르도록 서버가 pending 에 함께 내려준다(2026-08-01 합의).
    public let profileRegistered: Bool
    public let items: [ConsentItem]

    public init(status: ConsentPendingStatus, profileRegistered: Bool, items: [ConsentItem]) {
        self.status = status
        self.profileRegistered = profileRegistered
        self.items = items
    }

    /// 서버 필드 배포 전 과도기 — `profileRegistered` 가 없으면 미등록(false)으로 읽는다.
    /// 잘못돼도 온보딩을 한 번 더 보는 쪽(안전한 실패)이지 홈에 프로필 없이 앉는 쪽이 아니다.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(ConsentPendingStatus.self, forKey: .status)
        profileRegistered = try container.decodeIfPresent(Bool.self, forKey: .profileRegistered) ?? false
        items = try container.decode([ConsentItem].self, forKey: .items)
    }

    private enum CodingKeys: String, CodingKey {
        case status, profileRegistered, items
    }
}

/// 동의 항목 한 건. `version` 은 제출(submit)과 본문 조회(document)에 그대로 넘긴다.
public struct ConsentItem: Decodable, Equatable, Sendable {
    /// 항목 코드 (예: "TERMS_OF_SERVICE") — 서버가 관리하는 열린 집합이라 String 으로 둔다
    public let code: String
    /// 항목 제목 (예: "서비스 이용약관")
    public let label: String
    /// 필수 여부 — 필수는 거부(agreed: false) 제출 불가
    public let isRequired: Bool
    /// 지금 동의해야 하는 현행 버전
    public let version: Int
    /// 본문 등록 여부 — false 면 본문 보기 UI 를 숨긴다
    public let hasDocument: Bool

    public init(code: String, label: String, isRequired: Bool, version: Int, hasDocument: Bool) {
        self.code = code
        self.label = label
        self.isRequired = isRequired
        self.version = version
        self.hasDocument = hasDocument
    }

    private enum CodingKeys: String, CodingKey {
        case code, label, version, hasDocument
        case isRequired = "required"
    }
}

/// 동의 문서 본문 — 항목 탭 시 바텀시트에 띄우는 전문.
public struct ConsentDocument: Decodable, Equatable, Sendable {
    public let item: String
    public let version: Int
    public let title: String
    /// 마크다운 텍스트 — 마크다운 렌더러로 표시
    public let content: String

    public init(item: String, version: Int, title: String, content: String) {
        self.item = item
        self.version = version
        self.title = title
        self.content = content
    }
}

/// 제출 항목 한 건 — `item`·`version` 은 pending 이 내려준 값을 그대로 보낸다.
public struct ConsentSubmission: Encodable, Equatable, Sendable {
    public var item: String
    public var version: Int
    /// 필수 항목은 true 만 가능, 선택 항목은 거부(false)도 정상 제출
    public var agreed: Bool

    public init(item: String, version: Int, agreed: Bool) {
        self.item = item
        self.version = version
        self.agreed = agreed
    }
}

// MARK: - Client

/// 동의 API (D14 `/api/v1/consents/**`) — 온보딩 최초 동의와 약관 개정 재동의를 한 흐름으로 처리.
// @lat: [[api#Consent]]
public struct ConsentClient: Sendable {
    /// GET /consents/pending — 지금 동의가 필요한 항목. status 로 최초/재동의/최신 구분.
    public var pending: @Sendable () async throws -> ConsentPending
    /// GET /consents/{item}/versions/{version} — 문서 본문 (마크다운).
    public var document: @Sendable (_ item: String, _ version: Int) async throws -> ConsentDocument
    /// POST /consents — 동의 제출. 최초는 필수 5종 전체, 재동의는 pending 이 내려준 항목만.
    /// 첫 성공 제출 시 무료 이용권 3회 부여(서버).
    public var submit: @Sendable (_ items: [ConsentSubmission]) async throws -> Void

    public init(
        pending: @escaping @Sendable () async throws -> ConsentPending,
        document: @escaping @Sendable (_ item: String, _ version: Int) async throws -> ConsentDocument,
        submit: @escaping @Sendable (_ items: [ConsentSubmission]) async throws -> Void
    ) {
        self.pending = pending
        self.document = document
        self.submit = submit
    }
}

extension ConsentClient: TestDependencyKey {
    public static var testValue: ConsentClient {
        ConsentClient(
            pending: unimplemented("ConsentClient.pending"),
            document: unimplemented("ConsentClient.document"),
            submit: unimplemented("ConsentClient.submit")
        )
    }

    public static var previewValue: ConsentClient {
        ConsentClient(
            pending: {
                ConsentPending(
                    status: .notSubmitted,
                    profileRegistered: false,
                    items: [
                        // 만 14세만 전문이 없다(자체 확인 체크) — 시안 477:6308 의 «보기» 노출과 같은 배치.
                        ConsentItem(code: "AGE_OVER_14", label: "만 14세 이상", isRequired: true, version: 1, hasDocument: false),
                        ConsentItem(code: "TERMS_OF_SERVICE", label: "서비스 이용약관", isRequired: true, version: 1, hasDocument: true),
                        ConsentItem(code: "PERSONAL_INFO_COLLECTION", label: "개인정보 수집·이용", isRequired: true, version: 1, hasDocument: true),
                        ConsentItem(code: "INTERVIEW_RECORDING", label: "면접 영상·음성 촬영·저장", isRequired: true, version: 1, hasDocument: true),
                        ConsentItem(code: "OVERSEAS_TRANSFER", label: "개인정보 국외 이전", isRequired: true, version: 1, hasDocument: true)
                    ]
                )
            },
            document: { item, version in
                ConsentDocument(
                    item: item,
                    version: version,
                    title: "서비스 이용약관",
                    content: "제1조 (목적)\n이 약관은 프리뷰용 본문입니다."
                )
            },
            submit: { _ in }
        )
    }
}

public extension DependencyValues {
    var consentClient: ConsentClient {
        get { self[ConsentClient.self] }
        set { self[ConsentClient.self] = newValue }
    }
}
