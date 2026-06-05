import ProjectDescription

public extension TargetScript {
    /// 빌드 시 SwiftLint 를 실행하는 공용 pre-action.
    ///
    /// 헬퍼(`Project.core/.client/.feature`)와 App `Project.swift` 가 각 타겟의 `scripts` 에 1번씩 꽂으면,
    /// 그 타겟 빌드 때 자기 모듈 디렉터리(`$SRCROOT`)를 루트 `.swiftlint.yml` 기준으로 린트한다.
    /// SwiftLint 미설치 환경에선 경고만 내고 빌드를 막지 않는다.
    static let swiftLint: TargetScript = .pre(
        script: #"""
        export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
        if ! command -v swiftlint >/dev/null; then
            echo "warning: SwiftLint 미설치 — brew install swiftlint"
            exit 0
        fi
        ROOT=$(git -C "$SRCROOT" rev-parse --show-toplevel 2>/dev/null || echo "$SRCROOT")
        swiftlint lint --quiet --config "$ROOT/.swiftlint.yml" "$SRCROOT"
        """#,
        name: "SwiftLint",
        basedOnDependencyAnalysis: false
    )
}
