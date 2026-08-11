//
//  FileTransferClientLive.swift
//  CoreNetworkImplementation
//
//  Created by 서정원 on 26/08/05.
//

import ComposableArchitecture
import CoreNetworkInterface
import Foundation

extension FileTransferClient: @retroactive DependencyKey {
    public static var liveValue: FileTransferClient {
        live(session: .shared)
    }

    /// 세션 주입 팩토리 — Tests 가 스텁 세션으로 검증한다 (NetworkClient.live 와 같은 구도).
    public static func live(session: URLSession) -> FileTransferClient {
        FileTransferClient(
            upload: { url, contentType, fileURL in
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                let data: Data
                let response: URLResponse
                do {
                    // 파일 스트리밍 업로드 — 10분 영상을 메모리에 올리지 않는다.
                    (data, response) = try await session.upload(for: request, fromFile: fileURL)
                } catch let error as URLError where error.code == .cancelled {
                    // 구조적 동시성 취소는 실패가 아니다 — NetworkClient.live 와 같은 정규화
                    throw CancellationError()
                } catch let error as URLError {
                    throw NetworkError.transport(error.code)
                }
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw NetworkError.statusCode(http.statusCode, data)
                }
            }
        )
    }
}
