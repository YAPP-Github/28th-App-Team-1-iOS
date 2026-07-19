//
//  OnboardingPortfolioUploadView.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import SharedDesignSystemInterface
import SwiftUI
import UniformTypeIdentifiers

// Figma «STEP 4_포트폴리오 업로드» (기본 1609:9717 · 실패 1716:5462 · 업로드 중 1716:5533) 구현.
// 세 노드는 같은 화면의 하위 상태 변형 — store.upload 로만 분기하고 화면 전환은 없다.
@ViewAction(for: OnboardingPortfolioUploadFeature.self)
public struct OnboardingPortfolioUploadView: View {
    @Bindable public var store: StoreOf<OnboardingPortfolioUploadFeature>

    public init(store: StoreOf<OnboardingPortfolioUploadFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            progressBar
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    header
                    uploadSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            bottomBar
        }
        .background(Color.dsWhite.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .fileImporter(
            isPresented: $store.isFileImporterPresented,
            allowedContentTypes: [.pdf]
        ) { result in
            switch result {
            case let .success(url):
                send(.fileSelected(url))
            case .failure:
                send(.fileSelectionFailed)
            }
        }
    }

    // MARK: - 공통 골격 (STEP 1 과 동일)

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedClose)
            } label: {
                Image.DS.icClose
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.dsBlack)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
    }

    private var progressBar: some View {
        HStack(spacing: 2) {
            ForEach(1...store.totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= store.step ? Color.dsBlack : Color.dsGray50)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("필수")
                .dsTypography(.body7)
                .foregroundStyle(Color.dsGreen500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.dsBlack, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("포트폴리오를\n업로드해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.dsGray800)
                Text("포트폴리오를 분석해 면접 질문이 나와요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.dsGray500)
            }
        }
    }

    // MARK: - 업로드 섹션

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("업로드한 포트폴리오")
                .dsTypography(.body1)
                .foregroundStyle(Color.dsBlack)

            uploadCard

            if case let .failed(message) = store.upload {
                errorBanner(message)
            }

            listArea
        }
    }

    /// 파일 선택 진입 카드 — 세 하위 상태 모두 동일하게 노출된다 (Figma 1899:5219).
    private var uploadCard: some View {
        Button {
            send(.userTappedUploadCard)
        } label: {
            VStack(spacing: 11) {
                Circle()
                    .fill(Color.dsBlack)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image.DS.icUpload
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 22)
                            .foregroundStyle(Color.dsWhite)
                    }

                VStack(spacing: 4) {
                    Text("파일을 업로드해주세요")
                        .dsTypography(.body1)
                        .foregroundStyle(Color.dsGrayScale700)
                    Text("1개 파일, 최대 20Mb까지 가능합니다")
                        .dsTypography(.body8)
                        .foregroundStyle(Color.dsGrayScale600)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color.dsGrayScale100)
            .overlay {
                Rectangle().strokeBorder(Color.dsGrayScale200, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 업로드 실패 배너 (Figma 1716:5517) — failed 하위 상태에서만 노출.
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image.DS.icError
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(message)
                .dsTypography(.body8)
                .foregroundStyle(Color.dsError500)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsError200)
        .overlay {
            Rectangle().strokeBorder(Color.dsError300, lineWidth: 1)
        }
    }

    /// 카드 아래 리스트 영역 — 하위 상태에 따라 빈 박스 ↔ 파일 행.
    @ViewBuilder
    private var listArea: some View {
        switch store.upload {
        case .idle, .failed:
            emptyListBox
        case let .uploading(fileName, _):
            fileRow(fileName: fileName, statusText: "Processing...", showsProgress: true)
        case let .uploaded(fileName, _):
            // TODO: 업로드 완료 행 Figma 미확인 — 업로드 중 행에서 진행 스트립만 뺀 레이아웃으로 둔다.
            fileRow(fileName: fileName, statusText: "업로드 완료", showsProgress: false)
        }
    }

    /// 빈 상태 점선 박스 (Figma 1609:9789).
    private var emptyListBox: some View {
        Text("아직 첨부된 포트폴리오가 없어요")
            .dsTypography(.body5)
            .foregroundStyle(Color.emptyPlaceholderText)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.dsWhite)
            .overlay {
                // dash 간격은 Figma 수치 미제공 — 스크린샷 근사치.
                Rectangle().strokeBorder(
                    Color.emptyDashBorder,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
            }
    }

    /// 업로드 중·완료 파일 행 (Figma 1899:5284).
    private func fileRow(fileName: String, statusText: String, showsProgress: Bool) -> some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 8) {
                Text("PDF")
                    .dsTypography(.body7)
                    .foregroundStyle(Color.dsGreen500)
                    .frame(width: 40, height: 40)
                    .background(Color.dsGray800)

                VStack(alignment: .leading, spacing: 4) {
                    Text(fileName)
                        .dsTypography(.body4)
                        .foregroundStyle(Color.dsBlack)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(statusText)
                        .dsTypography(.body9)
                        .foregroundStyle(Color.fileStatusText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    send(.userTappedRemoveFile)
                } label: {
                    Image.DS.icCancelSmall
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.dsGrayScale400)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 11)
            .padding(.top, 11)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if showsProgress {
                uploadingProgressStrip
            }
        }
        .frame(height: 72)
        .background(Color.dsWhite)
        .overlay {
            Rectangle().strokeBorder(Color.dsGrayScale200, lineWidth: 1)
        }
    }

    /// 파일 행 하단 진행 스트립 — 업로드 진행률 이벤트가 없어(register 단일 호출)
    /// 디자인 고정 비율로 노출한다. TODO: 진행률 API 생기면 상태 주도로 교체.
    private var uploadingProgressStrip: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.dsGrayScale100)
                Rectangle()
                    .fill(Color.dsGreen500)
                    .frame(width: proxy.size.width * Self.uploadingProgressFraction)
            }
        }
        .frame(height: 10)
    }

    /// Figma 4.2 의 진행 스트립 비율 (52/335).
    private static let uploadingProgressFraction: CGFloat = 52.0 / 335.0

    // MARK: - 하단 CTA (이 스텝은 이전으로/계속하기 2버튼 — STEP 1 과 다름)

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedBack)
            } label: {
                Text("이전으로")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.dsWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.dsGray700)
                .frame(width: 1, height: 25)

            Button {
                send(.userTappedContinue)
            } label: {
                Text("계속하기")
                    .dsTypography(.sub7)
                    .foregroundStyle(store.isContinueEnabled ? Color.dsWhite : Color.dsGray400)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!store.isContinueEnabled)
        }
        .background(Color.dsBlack.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - 미승격 색상

private extension Color {
    /// 빈 상태 점선 보더 · #D3D7DD — Figma 변수 미바인딩 raw 값이라 DS 토큰화 보류.
    static let emptyDashBorder = Color(red: 211 / 255, green: 215 / 255, blue: 221 / 255)
    /// 빈 상태 안내 텍스트 · #A5B0C9 — Figma 변수 미바인딩 raw 값이라 DS 토큰화 보류.
    static let emptyPlaceholderText = Color(red: 165 / 255, green: 176 / 255, blue: 201 / 255)
    /// 파일 상태(Processing...) 텍스트 · #6F7687 — Figma 변수 미바인딩 raw 값이라 DS 토큰화 보류.
    static let fileStatusText = Color(red: 111 / 255, green: 118 / 255, blue: 135 / 255)
}

// MARK: - Previews

private let previewFileName = "홍길동 자기소개서_SK프롭티어 기업 면접.pdf"

#Preview("업로드 대기") {
    OnboardingPortfolioUploadView(
        store: Store(initialState: OnboardingPortfolioUploadFeature.State()) {
            OnboardingPortfolioUploadFeature()
        }
    )
}

#Preview("업로드 중") {
    OnboardingPortfolioUploadView(
        store: Store(
            initialState: OnboardingPortfolioUploadFeature.State(
                upload: .uploading(fileName: previewFileName, portfolioId: nil)
            )
        ) {
            OnboardingPortfolioUploadFeature()
        }
    )
}

#Preview("업로드 실패") {
    OnboardingPortfolioUploadView(
        store: Store(
            initialState: OnboardingPortfolioUploadFeature.State(
                upload: .failed(message: OnboardingPortfolioUploadFeature.unreadableFileMessage)
            )
        ) {
            OnboardingPortfolioUploadFeature()
        }
    )
}

#Preview("업로드 완료") {
    OnboardingPortfolioUploadView(
        store: Store(
            initialState: OnboardingPortfolioUploadFeature.State(
                upload: .uploaded(
                    fileName: previewFileName,
                    portfolioId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
                )
            )
        ) {
            OnboardingPortfolioUploadFeature()
        }
    )
}
