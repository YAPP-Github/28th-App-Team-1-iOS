//
//  DesignSystemCatalog.swift
//  SharedDesignSystemTesting
//
//  Created by EunseoKim on 26/07/29.
//

import SharedDesignSystemInterface
import SwiftUI

/// 디자인 시스템 전체를 한 화면에서 훑는 카탈로그 — 영역별 페이지로 들어간다.
///
/// **왜 Testing 타겟인가**: 카탈로그는 개발용 화면이라 App 이 링크하는 Interface 에 두면 릴리즈 바이너리에
/// 실려 나간다. `SharedDesignSystemTesting` 은 Tests(와 필요하면 Example)만 링크하므로 여기가 제자리다.
/// 부수효과로 **공개 API 만** 보이니(`internal` 인 `size`·`figmaName` 등은 못 씀) 화면이 쓸 수 있는 표면과
/// 카탈로그가 보여주는 표면이 자동으로 같아진다.
///
/// 보는 법: 이 파일의 `#Preview` 를 Xcode 캔버스에서 열면 된다 (앱 실행 불필요).
/// 새 파일을 추가했으면 `tuist generate` 를 먼저 돌려야 프로젝트에 들어온다.
public struct DesignSystemCatalog: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                NavigationLink("타이포그래피") { CatalogTypographyView() }
                NavigationLink("색상") { CatalogColorView() }
                NavigationLink("이미지") { CatalogImageView() }
                NavigationLink("Spacing · Outline") { CatalogSpacingView() }
                NavigationLink("버튼") { CatalogButtonView() }
                NavigationLink("컴포넌트") { CatalogComponentView() }
            }
            .dsTypography(.body3)
            .navigationTitle("HILIT DS")
        }
    }
}

#Preview("카탈로그") {
    DesignSystemCatalog()
}
