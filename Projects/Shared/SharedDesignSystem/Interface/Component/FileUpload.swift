//
//  FileUpload.swift
//  SharedDesignSystemInterface
//
//  Created by EunseoKim on 26/07/31.
//

// Figma: «file-upload» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=435-1371
//        status 축 4종 — before 435:1371 · empty 435:1369 · progressing 435:1378 · completed 435:1385

import SwiftUI

/// 포트폴리오 첨부 판 — Figma «file-upload» 435:1371 (`status` 축 4종).
///
/// 한 컴포넌트가 업로드 전/후를 다 그린다 — 판의 생김새가 상태마다 통째로 바뀐다:
/// `.before` g50 판 + 44pt 업로드 원 (h150) · `.empty` 흰 판 + g200 점선 ·
/// `.progressing`·`.completed` 파일 행 + 4pt 진행 바.
///
/// **탭은 이 타입이 갖지 않는다** — `.before` 판을 눌러 파일 선택기를 여는 건 화면마다
/// 경로가 달라서(`CountdownCard` 와 같은 판단) 호출부가 통째로 감싼다:
/// `Button { … } label: { FileUpload(.before(…)) }.buttonStyle(.plain)`.
/// 행 안의 X·미니 버튼만 의미가 하나로 닫혀서 클로저로 받는다.
/// 폭은 고정하지 않는다 — 시안 335 는 화면 좌우 여백 20 을 뺀 값이라 호출부 레이아웃 몫이다.
public struct FileUpload: View {
    /// Figma `status` 축. 값이 붙는 자리가 상태마다 달라서 payload 를 케이스가 나른다.
    public enum Status: Sendable, Equatable {
        /// 업로드 전 — g50 판(1pt g100 테두리) 안에 업로드 원 + 안내 두 줄 (Figma `status=before`)
        case before(title: String, guidance: String)
        /// 첨부 없음 — 흰 판 + g200 점선 테두리 + 회색 한 줄 (Figma `status=empty`)
        case empty(message: String)
        /// 업로드 중 — 파일 행 + g200 트랙 위 그린 진행 바 (Figma `status=progressing`)
        case progressing(Item, progress: Double)
        /// 완료 — 파일 행 + 꽉 찬 그린 바 (Figma `status=completed`)
        case completed(Item)
    }

    /// `.progressing`·`.completed` 행에 들어가는 값. 상태 문구 색은 케이스가 정한다 —
    /// 진행 중 g400 / 완료 g800(그린)이라 파라미터로 열지 않는다.
    public struct Item: Sendable, Equatable {
        /// 파일명. 한 줄로 잘린다(말줄임).
        public var name: String
        /// 파일명 아래 상태 문구 — «Processing...» / «Completed!» 같은 완성된 문자열.
        public var statusText: String
        /// 오른쪽 미니 버튼 라벨. `nil` 이면 버튼을 그리지 않는다 (Figma `card` 의 «버튼 미존재»).
        public var actionTitle: String?

        public init(name: String, statusText: String, actionTitle: String? = nil) {
            self.name = name
            self.statusText = statusText
            self.actionTitle = actionTitle
        }
    }

    private let status: Status
    private let onCancel: (() -> Void)?
    private let onAction: (() -> Void)?

    /// - Parameters:
    ///   - status: Figma `status` 축.
    ///   - onCancel: 파일 행의 X 버튼. `nil` 이면 X 를 그리지 않는다.
    ///   - onAction: 파일 행의 미니 버튼. 버튼의 표출 여부는 `Item.actionTitle` 이 정한다 —
    ///     라벨 없이 이 클로저만 주면 아무것도 그려지지 않는다.
    public init(
        _ status: Status,
        onCancel: (() -> Void)? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.status = status
        self.onCancel = onCancel
        self.onAction = onAction
    }

    public var body: some View {
        switch status {
        case let .before(title, guidance):
            beforePanel(title: title, guidance: guidance)
        case let .empty(message):
            emptyPanel(message: message)
        case let .progressing(item, progress):
            uploadingPanel(item: item, progress: progress, isCompleted: false)
        case let .completed(item):
            uploadingPanel(item: item, progress: 1, isCompleted: true)
        }
    }

    // MARK: - before

    /// 업로드 유도 판 — 고정 높이 150, 내용은 아래 정렬(시안 `justify-end`)에 가운데 맞춤.
    private func beforePanel(title: String, guidance: String) -> some View {
        VStack(spacing: Metric.beforeGap) {
            // 44pt b800 원과 흰 화살표가 에셋에 구워져 있다 — 원을 따로 그리지 않는다.
            Image.Upload.default
                .resizable()
                .scaledToFit()
                .frame(width: Metric.uploadSide, height: Metric.uploadSide)
            VStack(spacing: .ds(.p4)) {
                Text(title)
                    .dsTypography(.body2)
                    .foregroundStyle(Color.GrayScale.g900)
                Text(guidance)
                    .dsTypography(.body9)
                    .foregroundStyle(Color.GrayScale.g600)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.ds(.p10))
        .padding(.vertical, .ds(.p14))
        .frame(maxWidth: .infinity, minHeight: Metric.beforeHeight, alignment: .bottom)
        .background(Color.GrayScale.g50)
        .overlay {
            // 모서리 0 — 캡슐이 아니다.
            Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: .ds(.small))
        }
    }

    // MARK: - empty

    /// 첨부 없음 판 — 흰 바탕 + 점선. 시안 py27.5 는 스케일 밖 값이라 Metric 으로 보존한다.
    private func emptyPanel(message: String) -> some View {
        Text(message)
            .dsTypography(.body6)
            .foregroundStyle(Color.GrayScale.g300)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .ds(.p14))
            .padding(.vertical, Metric.emptyVerticalPadding)
            .background(Color.BlackWhite.white)
            .overlay {
                Rectangle().strokeBorder(
                    Color.GrayScale.g200,
                    style: StrokeStyle(lineWidth: .ds(.small), dash: Metric.emptyDash)
                )
            }
    }

    // MARK: - progressing · completed

    /// 파일 행 + 진행 바. 두 상태는 바의 색·길이만 다르다.
    private func uploadingPanel(item: Item, progress: Double, isCompleted: Bool) -> some View {
        VStack(spacing: 0) {
            fileRow(item: item, isCompleted: isCompleted)
            progressBar(progress: progress, isCompleted: isCompleted)
        }
    }

    /// 파일 한 줄 — 아래 테두리가 없다(진행 바가 바로 붙는다).
    ///
    /// 이 행은 Figma 에서 «card»(card-pdf, Part5) 인스턴스고 그 컴포넌트는 `FileCard` 로
    /// DS 에 있다 — 그래도 조립하지 않고 private 로 남긴다(결정): `FileCard` 는 4변 1.5
    /// 테두리 + 날짜·용량 메타 구조인데 이 행은 3변 테두리(아래는 진행 바가 잇는다) +
    /// 상태 문구 구조라, 조립하려면 `FileCard` 에 단일 소비자용 테두리·행 옵션을 열어야
    /// 한다. 여기서는 file-upload 가 쓰는 한 가지 구성(그린 파일 아이콘 + 파일명 +
    /// 상태 문구 + X + 미니 버튼)만 그린다.
    private func fileRow(item: Item, isCompleted: Bool) -> some View {
        HStack(spacing: .ds(.p12)) {
            // 36pt b800 사각과 그린 파일 글리프가 에셋에 구워져 있다.
            Image.File.green36
                .resizable()
                .scaledToFit()
                .frame(width: Metric.fileIconSide, height: Metric.fileIconSide)

            HStack(alignment: .top, spacing: .ds(.p8)) {
                fileTexts(item: item, isCompleted: isCompleted)
                if let onCancel {
                    Button(action: onCancel) {
                        smallIcon(Image.CancelMini.gray16)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let actionTitle = item.actionTitle {
                Button(action: onAction ?? {}) {
                    HStack(spacing: .ds(.p8)) {
                        smallIcon(Image.Video.default16)
                        Text(actionTitle)
                    }
                }
                .buttonStyle(.mini(.gray, layout: .withIcon))
            }
        }
        .padding(.ds(.p14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.BlackWhite.white)
        // 테두리가 위·좌·우 세 변에만 있고 두께가 1.5(outline-sb)다 — 아래는 진행 바가 잇는다.
        .overlay(alignment: .top) { rowBorder.frame(height: .ds(.semiBold)) }
        .overlay(alignment: .leading) { rowBorder.frame(width: .ds(.semiBold)) }
        .overlay(alignment: .trailing) { rowBorder.frame(width: .ds(.semiBold)) }
    }

    /// 파일명 한 줄(말줄임) + 상태 문구 + info 아이콘. 상태 문구 색만 케이스로 갈린다.
    private func fileTexts(item: Item, isCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: .ds(.p4)) {
            Text(item.name)
                .dsTypography(.body2)
                .foregroundStyle(Color.GrayScale.g700)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: Metric.statusGap) {
                Text(item.statusText)
                    .dsTypography(.body9)
                    .foregroundStyle(isCompleted ? Color.HilitGreen.g800 : Color.GrayScale.g400)
                smallIcon(Image.Info.disabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func smallIcon(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: Metric.smallIconSide, height: Metric.smallIconSide)
    }

    private var rowBorder: some View {
        Rectangle().fill(Color.GrayScale.g100)
    }

    /// 4pt 진행 바 — `.progressing` 은 g200 트랙 위 그린 채움, `.completed` 는 통째로 그린.
    private func progressBar(progress: Double, isCompleted: Bool) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(isCompleted ? Color.HilitGreen.g500 : Color.GrayScale.g200)
                Rectangle()
                    .fill(Color.HilitGreen.g500)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: Metric.progressBarHeight)
    }

    private enum Metric {
        /// 업로드 원 한 변 44 — Figma `upload/24px/default`(435:6) 프레임 크기.
        static let uploadSide: CGFloat = 44
        /// 파일 아이콘 한 변 36 — Figma `file/36px/green`.
        static let fileIconSide: CGFloat = 36
        /// info·cancel·video 아이콘 한 변 16.
        static let smallIconSide: CGFloat = 16
        /// `.before` 판 높이 150 — 시안 고정값.
        static let beforeHeight: CGFloat = 150
        /// 업로드 원과 안내 두 줄 사이 11 — @ds(spacing) 스케일 밖 값(4·8·10·12·14·16·20·22·24·40).
        static let beforeGap: CGFloat = 11
        /// `.empty` 상하 여백 27.5 — @ds(spacing) 스케일 밖 값. 판 높이 73 을 만드는 값이다.
        static let emptyVerticalPadding: CGFloat = 27.5
        /// 상태 문구와 info 아이콘 사이 6 — @ds(spacing) 스케일 밖 값.
        static let statusGap: CGFloat = 6
        /// 진행 바 높이 4.
        static let progressBarHeight: CGFloat = 4
        /// 점선 대시 — 시안이 Figma dash 설정을 노출하지 않아 눈으로 맞춘 값이다.
        /// @ds(border): 디자이너에게 dash/gap 확정값을 받으면 교체한다.
        static let emptyDash: [CGFloat] = [4, 4]
    }
}

// MARK: - Figma 원본 불일치
//
// ① `.before` 의 두 줄은 텍스트 스타일 변수에 묶이지 않은 raw 값이다 — SemiBold 16 / 행간 140% /
//    자간 -2%, Medium 12 / 행간 140% / 자간 -2%. 토큰(`body2`·`body9`)은 행간 130% · 자간 -2.5% 라
//    행간이 미세하게 좁다. 토큰 우선 원칙대로 토큰을 썼다(디자이너 확인 대기).
//    같은 파일의 `.empty`(`body6_m_14`)·행(`body2_sb_16`·`body9_m_12`)은 변수에 제대로 묶여 있다.
// ② `.progressing`·`.completed` 행은 «card»(card-pdf) 인스턴스고 DS 엔 `FileCard` 가 있다 —
//    그래도 private 유지로 결정(테두리 3변 vs 4변, 메타 vs 상태 문구 — 위 `fileRow` 독스트링).
//    시안이 행 모양을 바꾸면 두 파일을 같이 고쳐야 한다.
//
// MARK: - Figma 원본 값 조정
//
// `.before` 시안의 좌우 px84 는 뺐다 — 안내 문구가 nowrap 이라 「335 − 안내 문구 폭(167)」의
// 결과로 나온 수치지 설계된 여백이 아니다. 그대로 박으면 문구가 조금만 길어져도 두 줄로 접히면서
// 판 높이 150 이 깨진다. 가운데 정렬만 남겨 335 에서 시안과 같게 보이도록 했다(`TitleBox` 가
// px20 을 뺀 것과 같은 판단).

#Preview("file-upload") {
    ScrollView {
        VStack(spacing: .ds(.p20)) {
            FileUpload(.before(title: "파일을 업로드해주세요", guidance: "1개 파일, 최대 20Mb까지 가능합니다"))
            FileUpload(.empty(message: "아직 첨부된 포트폴리오가 없어요"))
            FileUpload(
                .progressing(
                    .init(name: "{파일명}.pdf", statusText: "Processing...", actionTitle: "버튼"),
                    progress: 0.16
                ),
                onCancel: {},
                onAction: {}
            )
            FileUpload(
                .completed(.init(name: "{파일명}.pdf", statusText: "Completed!", actionTitle: "버튼")),
                onCancel: {},
                onAction: {}
            )
            // 버튼·X 없는 최소 구성 + 아주 긴 파일명(한 줄 말줄임).
            FileUpload(.completed(.init(name: "아주 긴 파일명이라서 한 줄에 들어가지 않는 경우를 확인한다.pdf", statusText: "Completed!")))
        }
        .padding(.ds(.p20))
    }
    .background(Color.GrayScale.g50)
}
