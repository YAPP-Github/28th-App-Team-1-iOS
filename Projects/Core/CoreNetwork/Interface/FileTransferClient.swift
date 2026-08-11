//
//  FileTransferClient.swift
//  CoreNetworkInterface
//
//  Created by 서정원 on 26/08/05.
//

import ComposableArchitecture
import Foundation

// @lat: [[domain.map#네트워킹 인프라]]
/// presigned 절대 URL 파일 업로드 — Bearer 미첨부·envelope 없음. `NetworkClient`(baseURL 상대경로 +
/// envelope + 인증)와 계약 성격이 달라 별도 seam 으로 둔다. 2xx 밖은 `NetworkError.statusCode`.
public struct FileTransferClient: Sendable {
    /// `contentType` 은 발급 응답 값 그대로 — presigned 서명에 포함되어 다르면 저장소가 거부한다.
    public var upload: @Sendable (_ url: URL, _ contentType: String, _ fileURL: URL) async throws -> Void

    public init(upload: @escaping @Sendable (_ url: URL, _ contentType: String, _ fileURL: URL) async throws -> Void) {
        self.upload = upload
    }
}

extension FileTransferClient: TestDependencyKey {
    /// 컨벤션: testValue 는 반드시 unimplemented — 빈 클로저 금지 (스텁 누락을 테스트가 즉시 잡도록).
    public static var testValue: FileTransferClient {
        FileTransferClient(upload: unimplemented("FileTransferClient.upload"))
    }
}

public extension DependencyValues {
    var fileTransferClient: FileTransferClient {
        get { self[FileTransferClient.self] }
        set { self[FileTransferClient.self] = newValue }
    }
}
