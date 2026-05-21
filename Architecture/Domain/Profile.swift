import Foundation

/// 사용자 프로필 — ``User`` 의 편집 가능한 표현.
///
/// ``ProfileFeature`` 가 화면 단위로 다루는 도메인 모델입니다. `id` 는
/// ``User/id`` 와 동일한 값이며, 저장 시 ``AppFeature`` 가 이 매핑을
/// 사용해 목록·상세 화면의 ``User`` 를 갱신합니다.
struct Profile: Equatable, Identifiable, Codable, Sendable {
    let id: Int
    var displayName: String
    var bio: String
    var location: String?
}
