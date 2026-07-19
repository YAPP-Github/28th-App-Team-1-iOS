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
///
/// Figma 에 gray 컬렉션이 2벌 공존한다(팔레트 마이그레이션 중으로 보임):
/// 신형 `grayscale/gray-N` → `dsGrayN`, 구형 `Gray scale/N` → `dsGrayScaleN`.
/// 디자인이 한 벌로 정리되면 여기서 일괄 치환한다.
public extension Color {
    /// hilit black · #1A1B1F — CTA·뱃지 바탕, 강조 보더, 진행 바 활성.
    static let dsBlack = load("HilitBlack")
    /// hilit white · #FFFFFF — 화면·칩 바탕.
    static let dsWhite = load("HilitWhite")
    /// hilit green/500 · #ACEBA0 — 브랜드 그린 포인트 (뱃지 텍스트, 진행 스트립 등).
    static let dsGreen500 = load("HilitGreen500")
    /// hilit green/800 · #106100 — 성공 메시지 텍스트.
    static let dsGreen800 = load("HilitGreen800")

    // 신형 grayscale/gray-N
    /// grayscale/gray-50 · #F6F7F9 — 옅은 면 (진행 바 비활성, 뱃지 바탕 등).
    static let dsGray50 = load("Gray50")
    /// grayscale/gray-100 · #E0E1E7 — 입력 필드 보더, placeholder, 옅은 서브 텍스트.
    static let dsGray100 = load("Gray100")
    /// grayscale/gray-200 · #BCBEC6 — 비활성 탭 텍스트.
    static let dsGray200 = load("Gray200")
    /// grayscale/gray-300 · #9DA0AC — 헬퍼(idle) 텍스트.
    static let dsGray300 = load("Gray300")
    /// grayscale/gray-400 · #8A8D9C — 비활성 텍스트.
    static let dsGray400 = load("Gray400")
    /// grayscale/gray-600 · #636777 — 로딩 중 본문 텍스트.
    static let dsGray600 = load("Gray600")
    /// grayscale/gray-700 · #494C58 — CTA 구분선, 스피너 트랙, 카운터 텍스트.
    static let dsGray700 = load("Gray700")
    /// grayscale/gray-900 · #27282F — 진한 보조 텍스트 (분석 중 등).
    static let dsGray900 = load("Gray900")

    // 구형 Gray scale/N
    /// Gray scale/100 · #F3F4F6 — 진행 스트립 트랙.
    static let dsGrayScale100 = load("GrayScale100")
    /// Gray scale/200 · #E3E6EC — 입력창 보더 (집중 프로젝트·포폴 카드).
    static let dsGrayScale200 = load("GrayScale200")
    /// Gray scale/400 · #B6BCC8 — 완료 화면 서브 텍스트, 아이콘 틴트.
    static let dsGrayScale400 = load("GrayScale400")
    /// Gray scale/500 · #8990A0 — 보조 텍스트.
    static let dsGray500 = load("Gray500")
    /// Gray scale/600 · #6D7382 — 카드 캡션 텍스트.
    static let dsGrayScale600 = load("GrayScale600")
    /// Gray scale/700 · #3A3E47 — 파일명 등 진한 텍스트.
    static let dsGrayScale700 = load("GrayScale700")
    /// Gray scale/800 · #262A30 — 강조 본문 텍스트, PDF 뱃지 바탕.
    static let dsGray800 = load("Gray800")

    // error/N
    /// error/200 · #FFEBEB — 에러 배너 바탕.
    static let dsError200 = load("Error200")
    /// error/300 · #FFA6A6 — 에러 배너 보더.
    static let dsError300 = load("Error300")
    /// error/500 · #FF5757 — 에러 텍스트·스트립.
    static let dsError500 = load("Error500")
}
