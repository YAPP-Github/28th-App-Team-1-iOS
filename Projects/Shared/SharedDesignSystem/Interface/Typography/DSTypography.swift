//
//  DSTypography.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/18.
//

import CoreGraphics

// @lat: [[architecture#디자인 시스템]]
/// HILIT 타이포그래피 토큰 — Figma «Hilit_Style Guide_1»(node 988:3149) 스케일과 1:1.
/// 케이스명은 Figma 스타일명의 앞부분 (head1 = head1_sb_32) — 전체 대응은 `figmaName` 참조.
/// 사용: `Text("…").dsTypography(.head1)` (폰트+행간+자간 일괄) 또는 `Font.ds(.head1)` (폰트만).
public enum DSTypography: String, CaseIterable, Sendable {
    // Head — 화면 타이틀 (32·24px)
    case head1, head2, head3, head4, head5
    // Sub — 섹션·강조 (22·20·18px)
    case sub1, sub2, sub3, sub4, sub5, sub6, sub7, sub8, sub9
    // Body — 본문·캡션 (16·14·12px)
    case body1, body2, body3, body4, body5, body6, body7, body8, body9
}

public extension DSTypography {
    var size: CGFloat {
        switch self {
        case .head1, .head2: 32
        case .head3, .head4, .head5: 24
        case .sub1, .sub2, .sub3: 22
        case .sub4, .sub5, .sub6: 20
        case .sub7, .sub8, .sub9: 18
        case .body1, .body2, .body3: 16
        case .body4, .body5, .body6: 14
        case .body7, .body8, .body9: 12
        }
    }

    var weight: Pretendard.Weight {
        switch self {
        case .head1, .head3, .sub1, .sub4, .sub7, .body1, .body4, .body7: .semiBold
        case .head2, .head4, .sub2, .sub5, .sub8, .body2, .body5, .body8: .medium
        case .head5, .sub3, .sub6, .sub9, .body3, .body6, .body9: .regular
        }
    }

    /// Figma Line Height(%) — head1·head2 만 120%, 나머지 전부 130%.
    var lineHeightRatio: CGFloat {
        switch self {
        case .head1, .head2: 1.2
        default: 1.3
        }
    }

    /// 고정 행간(pt) — Figma 표의 Line Height(px) 열과 동일 (= size × ratio 반올림).
    var lineHeight: CGFloat {
        (size * lineHeightRatio).rounded()
    }

    /// 자간(pt) — Figma Letter Spacing 은 전 스타일 -2.5% (폰트 크기 비례).
    var letterSpacing: CGFloat {
        size * -0.025
    }

    /// Figma 텍스트 스타일명 (예: "head1_sb_32") — 디자이너 커뮤니케이션·핸드오프 대조용.
    var figmaName: String {
        "\(rawValue)_\(weight.figmaAbbreviation)_\(Int(size))"
    }
}
