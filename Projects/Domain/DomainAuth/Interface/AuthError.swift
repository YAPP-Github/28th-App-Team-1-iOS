/// State가 다르게 반응해야 하는 경우의 수만큼만 둔 에러. 원인 상세는 매핑 함수에서 로깅한다.
public enum AuthError: Error, Equatable, Sendable {
    case cancelled          // SDK 취소 — 얼럿 X
    case networkFailure     // 네트워크 문제
    case invalidCredential  // INVALID_CREDENTIAL / SOCIAL_LOGIN_FAILED (백엔드 연동 후 사용)
    case serverUnavailable  // 5xx (백엔드 연동 후 사용)
    case sessionExpired     // TOKEN_EXPIRED / INVALID_TOKEN / LOGIN_EXPIRED (갱신 로직에서 사용)
    case unexpected
}
