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

    /// 업로드 진행 스트립 비율(0~1) — 실제 진행률 이벤트가 없어(register 단일 호출) 시각적 가짜 진행이다.
    /// uploading 이면 0→0.9 로 천천히 차오르다 멈추고(폴링 대기), uploaded(READY) 시 1.0 으로 꽉 채운다.
    @State private var uploadProgress: CGFloat = 0

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
        .background(Color.BlackWhite.white.ignoresSafeArea())
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
        .onAppear { syncUploadProgress(progressPhase) }
        .onChange(of: progressPhase) { _, phase in syncUploadProgress(phase) }
    }

    /// 진행 스트립 애니메이션을 좌우하는 "단계"만 추린 값. `.uploading` 의 portfolioId 가
    /// nil→UUID 로 바뀌는(register 접수) associated value 변화로는 애니메이션이 0 부터
    /// 재시작하지 않도록, 원본 `UploadState` 대신 이 값으로 onChange 를 건다.
    private enum ProgressPhase: Equatable { case inactive, uploading, completed }

    private var progressPhase: ProgressPhase {
        switch store.upload {
        case .uploading: .uploading
        case .uploaded: .completed
        case .idle, .failed: .inactive
        }
    }

    /// 단계 전환에 맞춰 가짜 진행 스트립을 애니메이트한다.
    /// - uploading: 0 → 0.9 로 천천히(폴링이 끝날 때까지 90%에서 정지).
    /// - completed: 0.9 → 1.0 으로 빠르게 꽉 채움.
    /// - inactive : 0 으로 초기화.
    private func syncUploadProgress(_ phase: ProgressPhase) {
        switch phase {
        case .uploading:
            uploadProgress = 0
            withAnimation(.easeOut(duration: 12)) { uploadProgress = 0.9 }
        case .completed:
            withAnimation(.easeOut(duration: 0.35)) { uploadProgress = 1.0 }
        case .inactive:
            uploadProgress = 0
        }
    }

    // MARK: - 공통 골격 (STEP 1 과 동일)

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedClose)
            } label: {
                Image.Cancel.default24
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
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
                    .fill(step <= store.step ? Color.HilitBlack.b800 : Color.GrayScale.g50)
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
                .foregroundStyle(Color.HilitGreen.g500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.HilitBlack.b800, in: RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                Text("포트폴리오를\n업로드해 주세요.")
                    .dsTypography(.head3)
                    .foregroundStyle(Color.GrayScale.g800)
                Text("포트폴리오를 분석해 면접 질문이 나와요.")
                    .dsTypography(.body3)
                    .foregroundStyle(Color.GrayScale.g500)
            }
        }
    }

    // MARK: - 업로드 섹션

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("업로드한 포트폴리오")
                .dsTypography(.body1)
                .foregroundStyle(Color.HilitBlack.b800)

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
                // 검은 원 배경까지 에셋에 포함된 44px 판 (구판은 화살표만이라 원을 코드로 그렸다).
                Image.Upload.default
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                VStack(spacing: 4) {
                    Text("파일을 업로드해주세요")
                        .dsTypography(.body1)
                        .foregroundStyle(Color.GrayScale.g800)
                    Text("1개 파일, 최대 20Mb까지 가능합니다")
                        .dsTypography(.body8)
                        .foregroundStyle(Color.GrayScale.g500)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color.GrayScale.g50)
            .overlay {
                Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 업로드 실패 배너 (Figma 1716:5517) — failed 하위 상태에서만 노출.
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image.Issue.error16
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(message)
                .dsTypography(.body8)
                .foregroundStyle(Color.Error.e500)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Error.e200)
        .overlay {
            Rectangle().strokeBorder(Color.Error.e300, lineWidth: 1)
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
            // READY — 스트립을 100%(uploadProgress=1.0)로 꽉 채워 완료를 보여준다.
            fileRow(fileName: fileName, statusText: "업로드 완료", showsProgress: true)
        }
    }

    /// 빈 상태 점선 박스 (Figma 1609:9789).
    private var emptyListBox: some View {
        Text("아직 첨부된 포트폴리오가 없어요")
            .dsTypography(.body5)
            .foregroundStyle(Color.emptyPlaceholderText)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.BlackWhite.white)
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
                    .foregroundStyle(Color.HilitGreen.g500)
                    .frame(width: 40, height: 40)
                    .background(Color.GrayScale.g800)

                VStack(alignment: .leading, spacing: 4) {
                    Text(fileName)
                        .dsTypography(.body4)
                        .foregroundStyle(Color.HilitBlack.b800)
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
                    // 구 cancelSmall(20pt 맨 X, g200 틴트)의 새 시트 대응이 없다 —
                    // 입력 클리어 계열(cancel mini)로 대체. Figma 화면 확정 시 재검토.
                    Image.CancelMini.grey16
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
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
        .background(Color.BlackWhite.white)
        .overlay {
            Rectangle().strokeBorder(Color.GrayScale.g100, lineWidth: 1)
        }
    }

    /// 파일 행 하단 진행 스트립 — 업로드 진행률 이벤트가 없어(register 단일 호출)
    /// 디자인 고정 비율로 노출한다. TODO: 진행률 API 생기면 상태 주도로 교체.
    private var uploadingProgressStrip: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.GrayScale.g50)
                Rectangle()
                    .fill(Color.HilitGreen.g500)
                    .frame(width: proxy.size.width * uploadProgress)
            }
        }
        .frame(height: 10)
    }

    // MARK: - 하단 CTA (이 스텝은 이전으로/계속하기 2버튼 — STEP 1 과 다름)

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button {
                send(.userTappedBack)
            } label: {
                Text("이전으로")
                    .dsTypography(.sub7)
                    .foregroundStyle(Color.BlackWhite.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.GrayScale.g700)
                .frame(width: 1, height: 25)

            Button {
                send(.userTappedContinue)
            } label: {
                Text("계속하기")
                    .dsTypography(.sub7)
                    .foregroundStyle(store.isContinueEnabled ? Color.BlackWhite.white : Color.GrayScale.g400)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!store.isContinueEnabled)
        }
        .background(Color.HilitBlack.b800.ignoresSafeArea(edges: .bottom))
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
