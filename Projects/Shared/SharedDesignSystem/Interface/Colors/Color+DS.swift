//
//  Color+DS.swift
//  SharedDesignSystemInterface
//
//  Created by EunSeo on 26/07/18.
//

import SwiftUI
import UIKit

// @lat: [[architecture#디자인 시스템]]
public extension Color {
    /// 색 에셋 로드 단일 seam — 번들 해석을 한곳에 모으고 개발 빌드 assert 로 오타를 검출한다.
    /// 릴리스에서 누락 시 Color(name:) 기본 동작(투명)으로 폴백된다.
    static func load(_ name: String) -> Color {
        assert(
            UIColor(named: name, in: .module, compatibleWith: nil) != nil,
            "색 에셋 누락: \(name)"
        )
        return Color(name, bundle: .module)
    }
}

/// HILIT 색 토큰 — Figma 색 변수와 1:1 (주석 = Figma 변수명 · hex). 라이트 단일 값(다크모드 제한).
public extension Color {
    /// hilit black · #1A1B1F — CTA·뱃지 바탕, 강조 보더, 진행 바 활성.
    static let dsBlack = load("HilitBlack")
    /// hilit white · #FFFFFF — 화면·칩 바탕.
    static let dsWhite = load("HilitWhite")
    /// hilit green/500 · #ACEBA0 — 브랜드 그린 포인트 (뱃지 텍스트 등).
    static let dsGreen500 = load("HilitGreen500")
    /// grayscale/gray-50 · #F0F1F3 — 옅은 면 (진행 바 비활성 등).
    static let dsGray50 = load("Gray50")
    /// grayscale/gray-400 · #8A8D9C — 비활성 텍스트.
    static let dsGray400 = load("Gray400")
    /// Gray scale/500 · #8990A0 — 보조 텍스트.
    static let dsGray500 = load("Gray500")
    /// Gray scale/800 · #262A30 — 강조 본문 텍스트.
    static let dsGray800 = load("Gray800")
}
