//
//  Scheme+Templates.swift
//  ProjectDescriptionHelpers
//
//  Created by 서정원 on 26/07/15.
//

import ProjectDescription

public extension Scheme {
    /// 앱 환경별 스킴 팩토리 — Run/Archive/Profile/Analyze 전부를 한 Configuration 으로 고정한다.
    ///
    /// Tuist 자동 스킴은 Run=첫 debug(Dev)/Archive=첫 release(Release) 로 섞여
    /// QA 같은 중간 계를 실행·아카이브할 경로가 없다. 그래서 App 프로젝트는 자동 스킴을 끄고
    /// (`options: .options(automaticSchemesOptions: .disabled)`) 이 팩토리로 계별 스킴을 선언한다.
    static func app(name: String, configuration: ConfigurationName) -> Scheme {
        let app: TargetReference = "\(Project.Environment.appName)"
        return .scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: [app]),
            runAction: .runAction(configuration: configuration, executable: app),
            archiveAction: .archiveAction(configuration: configuration),
            profileAction: .profileAction(configuration: configuration, executable: app),
            analyzeAction: .analyzeAction(configuration: configuration)
        )
    }
}
