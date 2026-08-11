//
//  DocumentBlockTests.swift
//  FeatureAuthTests
//
//  Created by EunSeo on 26/08/02.
//

import XCTest

@testable import FeatureAuthImplementation

/// 동의 전문 마크다운 → 표시 블록 분해. 서버가 실제로 내리는 «### 제N조» 형식이 기준이다.
final class DocumentBlockTests: XCTestCase {
    func test_헤딩과_문단을_갈라낸다() {
        let markdown = """
        ### 제1조(목적)
        이 약관은 회사가 제공하는 서비스의 이용과 관련하여
        회사와 회원 간의 권리를 규정합니다.

        ### 제2조(정의)
        1. "서비스"란 AI 기반 모의 면접 코칭을 의미합니다.
        """

        XCTAssertEqual(DocumentBlock.parse(markdown), [
            .heading(level: 3, text: "제1조(목적)"),
            .paragraph("이 약관은 회사가 제공하는 서비스의 이용과 관련하여\n회사와 회원 간의 권리를 규정합니다."),
            .heading(level: 3, text: "제2조(정의)"),
            .paragraph("1. \"서비스\"란 AI 기반 모의 면접 코칭을 의미합니다.")
        ])
    }

    func test_헤딩_깊이는_샵_개수다() {
        XCTAssertEqual(DocumentBlock.parse("# 약관\n## 총칙"), [
            .heading(level: 1, text: "약관"),
            .heading(level: 2, text: "총칙")
        ])
    }

    /// `#` 뒤에 공백이 없으면 헤딩이 아니다 — 본문에 섞인 «#1 항목» 을 제목으로 올리지 않는다.
    func test_공백_없는_샵은_문단으로_둔다() {
        XCTAssertEqual(DocumentBlock.parse("#1 항목은 다음과 같습니다."), [
            .paragraph("#1 항목은 다음과 같습니다.")
        ])
    }

    func test_본문이_비면_블록도_없다() {
        XCTAssertEqual(DocumentBlock.parse(""), [])
        XCTAssertEqual(DocumentBlock.parse("\n\n  \n"), [])
    }
}
