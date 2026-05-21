import Foundation

/// 사용자 도메인 모델.
///
/// ``UserClient`` 가 외부 시스템에서 읽어와 ``UserListFeature`` 의 목록과
/// ``UserDetailFeature`` 의 상세 화면에서 공유합니다. ``ProfileFeature`` 가
/// 편집 결과를 저장하면 ``AppFeature`` 가 `name`/`bio` 를 다시 써넣습니다.
struct User: Equatable, Identifiable, Codable, Sendable {
    let id: Int
    var name: String
    var email: String
    var bio: String?
}
