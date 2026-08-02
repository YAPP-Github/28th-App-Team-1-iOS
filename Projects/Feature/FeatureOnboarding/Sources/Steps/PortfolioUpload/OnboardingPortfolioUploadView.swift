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

// Figma «Onboarding_PortfolioUpload» https://figma.com/design/JL9YPbqBqmaC9Z0I3SzDZS/?node-id=443-9568
//        실패 443:9624 — 업로드 판과 첨부 목록 사이에 «info-field» 한 줄(443:9641)이 낀다.
// 업로드 중·완료 프레임은 이번 시안에 없다(대기·실패 두 칸만 그려져 있다) — 첨부 목록 자리에
// DS «file-upload» 컴포넌트의 progressing(435:1378)·completed(435:1385) 변형을 그대로 끼운다.
// 네 상태는 같은 화면의 하위 상태 변형 — store.upload 로만 분기하고 화면 전환은 없다.
@ViewAction(for: OnboardingPortfolioUploadFeature.self)
public struct OnboardingPortfolioUploadView: View {
    @Bindable public var store: StoreOf<OnboardingPortfolioUploadFeature>

    public init(store: StoreOf<OnboardingPortfolioUploadFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 시안 gap 8 — 네비바 그룹(443:9574)과 진행 바 그룹(443:9577) 사이.
            DashIndicator(count: store.totalSteps, current: store.step)
                .padding(.top, .ds(.p8))
            ScrollView {
                VStack(alignment: .leading, spacing: .ds(.p16)) {
                    header
                    uploadSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            bottomBar
        }
        .background(Color.BlackWhite.white.ignoresSafeArea())
        .hilitNavigationBar(
            background: .filled,
            allowsSwipeBack: !store.upload.isUploading,
            onClose: { send(.userTappedClose) }
        )
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

    // MARK: - 머리글

    /// Figma «title-box» 443:9580 — 뱃지 «필수» · 마커 «포트폴리오» · 서브 한 줄.
    /// 좌우 20 은 컴포넌트가 갖지 않는다(DS 독스트링) — 화면이 준다.
    private var header: some View {
        TitleBox(
            [.init("포트폴리오를", highlight: "포트폴리오"), "업로드해 주세요."],
            tag: "필수",
            sub: "포트폴리오를 분석해 면접 질문이 나와요."
        )
        .padding(.horizontal, .ds(.p20))
        .padding(.top, .ds(.p20))
    }

    // MARK: - 업로드 섹션

    /// Figma 443:9581 — 라벨 · 업로드 판 · (실패 시 안내 줄) · 첨부 목록을 간격 10 으로 쌓는다.
    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: .ds(.p10)) {
            // @ds(color): #000000 → HilitBlack.b800 — 섹션 라벨(443:9583). 시안이 변수 미바인딩 순검정이다.
            Text("업로드한 포트폴리오")
                .dsTypography(.body2)
                .foregroundStyle(Color.HilitBlack.b800)

            uploadCard

            if case let .failed(message) = store.upload {
                // 시안 443:9641 은 자리표시 문구에 «서버에러메세지» 주석이 붙어 있다 — 문구는 서버 message 우선.
                InfoField(message, style: .error)
            }

            attachedFile
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .ds(.p20))
        // @ds(spacing): 30 — 업로드 섹션 상하 여백. 스케일(4·8·10·12·14·16·20·22·24·40) 밖 값.
        .padding(.vertical, 30)
    }

    /// 파일 선택 진입 판 (Figma 443:9584 = «file-upload» status=before).
    /// 탭은 `FileUpload` 가 갖지 않아 호출부가 통째로 감싼다 — DS 독스트링이 정한 사용법.
    private var uploadCard: some View {
        Button {
            send(.userTappedUploadCard)
        } label: {
            FileUpload(.before(title: "파일을 업로드해주세요", guidance: "1개 파일, 최대 20Mb까지 가능합니다"))
        }
        .buttonStyle(.plain)
    }

    /// 판 아래 첨부 목록 — 하위 상태에 따라 빈 판(443:9585) ↔ 파일 행.
    /// 파일 행의 상태 문구는 이번 시안에 프레임이 없어 기존 문구를 유지한다
    /// (컴포넌트 시트의 «Processing...»·«Completed!» 는 «{파일명}.pdf» 와 같은 자리표시 텍스트).
    ///
    /// 진행 바 값은 리듀서의 `UploadState.phaseProgress` — register/폴링 두 단계를 가리키는
    /// 단계 마커다. 여기서 타이머로 굴리지 않는다(실측 진행률이 없어 View 가 지어내면 실제와 어긋난다).
    @ViewBuilder
    private var attachedFile: some View {
        switch store.upload {
        case .idle, .failed:
            FileUpload(.empty(message: "아직 첨부된 포트폴리오가 없어요"))
        case let .uploading(fileName, _):
            FileUpload(
                .progressing(.init(name: fileName, statusText: "Processing..."), progress: store.upload.phaseProgress),
                onCancel: { send(.userTappedRemoveFile) }
            )
            // 접수(register 응답)로 단계가 넘어가는 순간을 이징한다 — 값이 두 개뿐이라 그냥 두면
            // 바가 뚝 끊긴다. 애니메이션이 붙는 대상은 «실제 상태 전이» 하나뿐이고, 폴링 구간은
            // 여전히 정지해 있다(진행률 이벤트가 없다 — `phaseProgress` TODO).
            .animation(.easeOut(duration: 0.3), value: store.upload.phaseProgress)
        case let .uploaded(fileName, _):
            FileUpload(
                .completed(.init(name: fileName, statusText: "업로드 완료")),
                onCancel: { send(.userTappedRemoveFile) }
            )
        }
    }

    // MARK: - 하단 CTA

    /// Figma 443:9570 «button-large/bottom» status=2button-1disabled — 완료 전까지 계속하기가 비활성.
    private var bottomBar: some View {
        ButtonLarge(.bottom, tone: .dark) {
            Button("이전으로") { send(.userTappedBack) }
        } trailing: {
            Button("계속하기") { send(.userTappedContinue) }
                .disabled(!store.isContinueEnabled)
        }
    }
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

// 업로드 중은 진행 바가 두 단계로 갈린다(`UploadState.phaseProgress`) — 두 칸을 다 걸어 둔다.
#Preview("업로드 중 — 등록 요청") {
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

#Preview("업로드 중 — 서버 처리 폴링") {
    OnboardingPortfolioUploadView(
        store: Store(
            initialState: OnboardingPortfolioUploadFeature.State(
                upload: .uploading(
                    fileName: previewFileName,
                    portfolioId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
                )
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
