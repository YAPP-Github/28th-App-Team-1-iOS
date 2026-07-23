//
//  Pretendard.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/18.
//

import CoreText
import Foundation

/// HILIT 서비스 폰트 패밀리. 타이포 토큰(`DSTypography`)이 쓰는 웨이트만 노출한다.
public enum Pretendard {
    public enum Weight: String, CaseIterable, Sendable {
        case regular = "Regular"
        case medium = "Medium"
        case semiBold = "SemiBold"
        case bold = "Bold"

        /// 번들 파일명이자 PostScript 이름 (예: "Pretendard-SemiBold")
        public var postScriptName: String { "Pretendard-\(rawValue)" }

        /// Figma 스타일명의 웨이트 축약 (head1_**sb**_32)
        var figmaAbbreviation: String {
            switch self {
            case .regular: "r"
            case .medium: "m"
            case .semiBold: "sb"
            case .bold: "b"
            }
        }
    }

    /// 최초 접근 시 1회만 실행되는 폰트 등록 (static let = lazy + thread-safe).
    /// 토큰 접근이 곧 등록 트리거라 App 쪽 배선이 필요 없다.
    /// 리소스 누락은 개발 빌드 assert 로 검출 — 릴리스는 시스템 폰트로 폴백된다.
    static let registerOnce: Void = {
        for weight in Weight.allCases {
            guard let url = Bundle.module.url(
                forResource: weight.postScriptName,
                withExtension: "otf"
            ) else {
                assertionFailure("Pretendard 폰트 리소스 누락: \(weight.postScriptName).otf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
