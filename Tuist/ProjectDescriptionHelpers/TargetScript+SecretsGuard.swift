//
//  TargetScript+SecretsGuard.swift
//  ProjectDescriptionHelpers
//
//  Created by 서정원 on 26/07/15.
//

import ProjectDescription

public extension TargetScript {
    /// 앱 타겟 pre-action — `KAKAO_NATIVE_APP_KEY` 미설정을 빌드 단계에서 검출한다.
    ///
    /// `AppSecrets` 의 assertionFailure 는 Release 에서 no-op 이라, Secrets.xcconfig 없는
    /// 머신에서 아카이브하면 빈 키(카카오 로그인·URL scheme 고장)로 조용히 출시될 수 있다.
    /// 배포 계(QA/Release)는 빌드를 실패시키고, Dev 는 경고만 내 시크릿 없이도 UI 작업이 가능하게 둔다.
    static let kakaoKeyGuard: TargetScript = .pre(
        script: #"""
        if [ -z "${KAKAO_NATIVE_APP_KEY}" ]; then
            MSG="KAKAO_NATIVE_APP_KEY 가 비어 있습니다 — Projects/App/Config/Secrets.xcconfig 를 확인하세요 (docs/getting-started.md)"
            case "${CONFIGURATION}" in
                QA|Release) echo "error: ${MSG}"; exit 1 ;;
                *) echo "warning: ${MSG} — Dev 는 경고만 내며, 카카오 로그인만 동작하지 않습니다." ;;
            esac
        fi
        """#,
        name: "KakaoKeyGuard",
        basedOnDependencyAnalysis: false
    )
}
