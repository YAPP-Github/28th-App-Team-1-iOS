//
//  OnboardingPortfolioUploadFeature.swift
//  FeatureOnboarding
//
//  Created by EunSeo on 26/07/19.
//

import ComposableArchitecture
import DomainPortfolioInterface
import Foundation
import PDFKit

// @lat: [[onboarding#포트폴리오 업로드]]
/// 온보딩 STEP 4 — 포트폴리오 업로드. PDF 1개(20MB 이하)를 골라 서버에 등록하고,
/// PROCESSING 폴링이 READY 가 될 때까지 기다린다. 대기/업로드 중/실패/완료는
/// 별도 화면 push 없이 `UploadState` 하위 상태로만 전환한다 (Figma 4 · 4.1 · 4.2).
/// 완료 결과는 delegate(.continueRequested(portfolioId:))로 코디네이터에 올린다.
@Reducer
public struct OnboardingPortfolioUploadFeature {
    /// 업로드 진행 하위 상태 — 화면 전환 없이 리스트 영역 렌더만 바꾼다.
    public enum UploadState: Equatable, Sendable {
        /// 대기 — 아직 첨부된 파일 없음 (빈 점선 박스).
        case idle
        /// 업로드·서버 처리 중 — register 접수 전이면 portfolioId 는 nil (Figma 4.2).
        case uploading(fileName: String, portfolioId: UUID?)
        /// 실패 — 에러 배너 + 빈 점선 박스 (Figma 4.1).
        case failed(message: String)
        /// 완료 — 파일 행 표시, 계속하기 활성.
        case uploaded(fileName: String, portfolioId: UUID)

        /// 업로드·폴링 진행 중 — 이 동안만 스와이프백을 막는다(이탈 = 폴링·서버 파일 버림).
        public var isUploading: Bool {
            if case .uploading = self { true } else { false }
        }
    }

    @ObservableState
    public struct State: Equatable {
        /// 프로그레스 바 분모 — 온보딩 전체 단계 수.
        public let totalSteps: Int
        /// 프로그레스 바 분자 — 이 화면의 단계(1-based).
        public let step: Int
        /// 업로드 하위 상태.
        public var upload: UploadState
        /// 파일 선택 시트(fileImporter) 표시 여부 — View binding 으로 닫힘까지 동기화된다.
        public var isFileImporterPresented = false

        public var isContinueEnabled: Bool {
            if case .uploaded = upload { true } else { false }
        }

        public init(step: Int = 4, totalSteps: Int = 5, upload: UploadState = .idle) {
            self.step = step
            self.totalSteps = totalSteps
            self.upload = upload
        }
    }

    public enum Action: ViewAction {
        case view(View)
        case inner(Inner)
        case delegate(Delegate)

        /// 사용자 입력·생명주기. View 의 send(...) 로만 방출된다.
        /// fileImporter 표시 바인딩을 위해 BindableAction 채택 (BindingReducer(action: \.view)).
        @CasePathable
        public enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case userTappedClose
            case userTappedBack
            case userTappedContinue
            case userTappedUploadCard
            case userTappedRemoveFile
            /// fileImporter 선택 완료 — security-scoped URL.
            case fileSelected(URL)
            /// fileImporter 자체 실패 (파일 접근 불가 등).
            case fileSelectionFailed
        }

        /// effect 결과·리듀서 내부 신호. 리듀서만 방출한다.
        @CasePathable
        public enum Inner: Equatable, Sendable {
            /// POST /portfolios 접수 응답 (202 PROCESSING — 드물게 즉시 READY/FAILED).
            case uploadAccepted(PortfolioProcessing)
            /// GET /portfolios/{id}/status 폴링 응답.
            case statusPolled(PortfolioProcessing)
            /// 파일 읽기·용량 초과·네트워크 등 클라이언트 측 실패.
            case uploadFailed(message: String)
        }

        /// 코디네이터(OnboardingFeature) 통보. 부모는 이것만 매칭한다 (D1).
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            /// 업로드 완료 — 다음 스텝으로. portfolioId 는 서버 등록 결과, fileName 은 draft 복원용.
            case continueRequested(portfolioId: UUID, fileName: String)
            /// 하단 «이전으로» — 코디네이터가 스택을 pop.
            case backRequested
            /// 온보딩 이탈(X) 요청 — dismiss 는 코디네이터 몫.
            case closeRequested
        }
    }

    /// FAILED_FILE 기본 문구 — Figma 4.1 명세. 서버 message 가 있으면 그것을 우선한다.
    static let unreadableFileMessage = "이 PDF에서 글자를 읽지 못했어요.\n글자가 드래그로 선택되는 PDF로 다시 올려주세요."
    /// 파일 읽기·네트워크 등 일반 실패 문구 — 디자인 미정, 임시.
    static let genericFailureMessage = "업로드에 실패했어요.\n잠시 후 다시 시도해 주세요."
    /// 용량 초과 문구 — 디자인 미정, 임시 (서버 FILE_TOO_LARGE 와 동일 조건).
    static let oversizedFileMessage = "20MB 이하의 PDF 파일만 업로드할 수 있어요."
    /// 페이지 초과 문구 — PRD S2 확정 (서버 PAGE_COUNT_EXCEEDED 와 동일 조건).
    static let pageExceededMessage = "페이지가 너무 많아요.\n30페이지 이하 PDF로 올려주세요."
    /// 암호 PDF 문구 — PRD S2 확정 (열기 암호 걸린 PDF 는 파싱 불가).
    static let encryptedFileMessage = "암호가 걸린 PDF는 열 수 없어요.\n암호를 푼 PDF로 올려주세요."
    /// 업로드 상한 20MB — Figma «최대 20Mb» · 서버 검증 FILE_TOO_LARGE.
    static let maxFileSizeBytes = 20 * 1024 * 1024
    /// 페이지 상한 30p — PRD S2 · 서버 검증 PAGE_COUNT_EXCEEDED. 클라 선검증(서버 실측 재검증).
    static let maxPageCount = 30
    /// 처리 상태 폴링 주기 — PortfolioClient 가이드(3~5초)의 하한.
    static let pollInterval: Duration = .seconds(3)

    private enum CancelID { case upload }

    @Dependency(\.portfolioClient) var portfolioClient
    @Dependency(\.portfolioFileReader) var fileReader
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)

        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduceView(&state, action)
            case let .inner(action):
                return reduceInner(&state, action)
            case .delegate:
                return .none
            }
        }
    }

    private func reduceView(_ state: inout State, _ action: Action.View) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .userTappedClose:
            return .send(.delegate(.closeRequested))

        case .userTappedBack:
            return .send(.delegate(.backRequested))

        case .userTappedContinue:
            guard case let .uploaded(fileName, portfolioId) = state.upload else { return .none }
            return .send(.delegate(.continueRequested(portfolioId: portfolioId, fileName: fileName)))

        case .userTappedUploadCard:
            // 계정당 1개 제한(PORTFOLIO_ALREADY_EXISTS) — 업로드 중·완료엔 재선택을 막는다.
            // 교체는 파일 행의 X 로 제거한 뒤 다시 업로드하는 UX.
            switch state.upload {
            case .idle, .failed:
                state.isFileImporterPresented = true
                return .none
            case .uploading, .uploaded:
                return .none
            }

        case let .fileSelected(url):
            let fileName = url.lastPathComponent
            state.upload = .uploading(fileName: fileName, portfolioId: nil)
            return .run { send in
                // 클라 선검증 = UX 용 빠른 차단. 최종 판정은 서버 실측 재검증(글자 수·암호 최종 판별은 서버).
                let file = try await fileReader.read(url)
                guard file.data.count <= Self.maxFileSizeBytes else {
                    await send(.inner(.uploadFailed(message: Self.oversizedFileMessage)))
                    return
                }
                guard !file.isEncrypted else {
                    await send(.inner(.uploadFailed(message: Self.encryptedFileMessage)))
                    return
                }
                if let pageCount = file.pageCount, pageCount > Self.maxPageCount {
                    await send(.inner(.uploadFailed(message: Self.pageExceededMessage)))
                    return
                }
                let upload = PortfolioUpload(
                    fileName: fileName,
                    fileSize: file.data.count,
                    pageCount: file.pageCount,
                    data: file.data
                )
                await send(.inner(.uploadAccepted(try await portfolioClient.register(upload))))
            } catch: { error, send in
                await send(.inner(.uploadFailed(message: Self.failureMessage(for: error))))
            }
            .cancellable(id: CancelID.upload, cancelInFlight: true)

        case .fileSelectionFailed:
            state.upload = .failed(message: Self.genericFailureMessage)
            return .none

        case .userTappedRemoveFile:
            switch state.upload {
            case let .uploading(_, portfolioId):
                state.upload = .idle
                return .merge(.cancel(id: CancelID.upload), deleteIfRegistered(portfolioId))
            case let .uploaded(_, portfolioId):
                state.upload = .idle
                return deleteIfRegistered(portfolioId)
            case .idle, .failed:
                return .none
            }
        }
    }

    private func reduceInner(_ state: inout State, _ action: Action.Inner) -> Effect<Action> {
        switch action {
        case .uploadAccepted(let processing), .statusPolled(let processing):
            return applyProcessing(&state, processing)

        case let .uploadFailed(message):
            state.upload = .failed(message: message)
            return .none
        }
    }

    /// 등록·폴링 공통 응답 반영 — PROCESSING 이면 폴링을 잇고, READY/FAILED 면 하위 상태를 확정한다.
    private func applyProcessing(_ state: inout State, _ processing: PortfolioProcessing) -> Effect<Action> {
        // X(제거) 등으로 업로드 흐름이 이미 끊겼으면 늦게 도착한 응답을 무시한다.
        guard case let .uploading(fileName, _) = state.upload else { return .none }

        switch processing.status {
        case .processing:
            state.upload = .uploading(fileName: fileName, portfolioId: processing.portfolioId)
            return .run { send in
                try await clock.sleep(for: Self.pollInterval)
                await send(.inner(.statusPolled(try await portfolioClient.status(processing.portfolioId))))
            } catch: { error, send in
                await send(.inner(.uploadFailed(message: Self.failureMessage(for: error))))
            }
            .cancellable(id: CancelID.upload, cancelInFlight: true)

        case .ready:
            state.upload = .uploaded(fileName: fileName, portfolioId: processing.portfolioId)
            return .none

        // TODO: 200 + FAILED_* 문구 정책 PRD 미정 — 서버 message 우선, 없을 때만 클라 문구. 확정되면 재확인.
        case .failedFile:
            state.upload = .failed(message: processing.message ?? Self.unreadableFileMessage)
            return .none

        case .failedSystem:
            state.upload = .failed(message: processing.message ?? Self.genericFailureMessage)
            return .none
        }
    }

    /// 업로드·폴링 실패 문구 — 서버 4xx 는 원문 message 를 그대로 싣는다.
    /// TODO: 서버 문구 그대로 노출은 임시 규칙(ServerError.alertMessage 와 같은 계). 코드별 클라 카피 확정 시 교체.
    /// TODO: PORTFOLIO_ALREADY_EXISTS 는 PRD 상 «기존 삭제 후 재업로드» dialog 안(자동 교체 금지) — 지금은 배너 문구만.
    static func failureMessage(for error: any Error) -> String {
        (error as? PortfolioError)?.userMessage ?? genericFailureMessage
    }

    /// 서버에 이미 등록된 파일 제거 — 계정당 1개 제한이라 지워야 재업로드가 가능하다.
    private func deleteIfRegistered(_ portfolioId: UUID?) -> Effect<Action> {
        guard let portfolioId else { return .none }
        return .run { _ in
            // TODO: 삭제 실패 UX 미정 — 우선 무시한다 (실패 시 다음 업로드에서 PORTFOLIO_ALREADY_EXISTS 로 드러남).
            _ = try? await portfolioClient.delete(portfolioId)
        }
    }
}

// MARK: - PortfolioFileReader

/// 선택한 PDF 의 바이트 + 클라 선검증용 메타(페이지 수·암호 여부).
/// 페이지 수는 파싱 실패 시 nil — 그 경우 서버 실측에 판정을 위임한다.
public struct PortfolioFile: Equatable, Sendable {
    /// PDF 바이너리
    public var data: Data
    /// PDF 페이지 수 — 파싱 불가(손상·비PDF) 시 nil.
    public var pageCount: Int?
    /// 열기 암호가 걸린 PDF 여부.
    public var isEncrypted: Bool

    public init(data: Data, pageCount: Int? = nil, isEncrypted: Bool = false) {
        self.data = data
        self.pageCount = pageCount
        self.isEncrypted = isEncrypted
    }
}

/// fileImporter 가 준 security-scoped URL 에서 PDF 바이트·메타를 읽는 파일 IO seam.
/// TODO: 외부 IO 는 Domain/Core 모듈이 원칙 — 모듈 추가는 이 스텝 범위 밖이라 임시로 Feature 에 둔다.
public struct PortfolioFileReader: Sendable {
    public var read: @Sendable (URL) async throws -> PortfolioFile

    public init(read: @escaping @Sendable (URL) async throws -> PortfolioFile) {
        self.read = read
    }
}

extension PortfolioFileReader: DependencyKey {
    public static var liveValue: PortfolioFileReader {
        PortfolioFileReader { url in
            let isScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isScoped { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            // PDFKit 파싱 — 페이지 수·암호 여부만 뽑는다(내용 추출·글자 수 판정은 서버 Tika).
            let document = PDFDocument(data: data)
            return PortfolioFile(
                data: data,
                pageCount: document?.pageCount,
                isEncrypted: document?.isEncrypted ?? false
            )
        }
    }

    public static var testValue: PortfolioFileReader {
        PortfolioFileReader(read: unimplemented("PortfolioFileReader.read"))
    }
}

public extension DependencyValues {
    var portfolioFileReader: PortfolioFileReader {
        get { self[PortfolioFileReader.self] }
        set { self[PortfolioFileReader.self] = newValue }
    }
}
