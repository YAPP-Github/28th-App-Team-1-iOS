//
//  ConsentDocumentBlock.swift
//  FeatureAuthImplementation
//
//  Created by EunSeo on 26/08/02.
//

import Foundation

/// 동의 전문(서버 마크다운)의 표시 블록 — 헤딩과 문단 두 갈래.
///
/// SwiftUI `Text` 의 마크다운은 인라인 문법(굵게·기울임·링크)만 처리하고 **블록 문법은 모른다** —
/// `### 제1조(목적)` 이 «###» 까지 그대로 찍힌다. 전문에 있는 블록 문법은 ATX 헤딩뿐이라
/// 마크다운 렌더러를 들이는 대신 그 한 겹만 여기서 걷어내고, 인라인은 계속 `Text` 에 맡긴다.
enum DocumentBlock: Equatable {
    /// `#` 개수 = 깊이. 표시 타이포는 화면(`AuthTermsView`)이 정한다.
    case heading(level: Int, text: String)
    /// 빈 줄로 끊기는 문단. 안쪽 줄바꿈은 살린다(조항 번호 목록이 한 줄씩 내려와야 해서).
    case paragraph(String)

    static func parse(_ markdown: String) -> [DocumentBlock] {
        var blocks: [DocumentBlock] = []
        var lines: [String] = []

        func flushParagraph() {
            guard !lines.isEmpty else { return }
            blocks.append(.paragraph(lines.joined(separator: "\n")))
            lines = []
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
            } else if let heading = heading(from: line) {
                flushParagraph()
                blocks.append(heading)
            } else {
                lines.append(line)
            }
        }
        flushParagraph()

        return blocks
    }

    /// ATX 헤딩만 인정한다 — `#` 뒤에 공백이 있어야 헤딩. `#태그` 같은 본문은 문단으로 남는다.
    private static func heading(from line: String) -> DocumentBlock? {
        let hashes = line.prefix { $0 == "#" }
        let rest = line.dropFirst(hashes.count)
        guard !hashes.isEmpty, rest.hasPrefix(" ") else { return nil }
        return .heading(level: hashes.count, text: rest.trimmingCharacters(in: .whitespaces))
    }
}
