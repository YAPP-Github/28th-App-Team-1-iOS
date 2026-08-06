//
//  InterviewVideoUploadQueueTests.swift
//  DomainInterviewTests
//
//  Created by 서정원 on 26/08/06.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import Foundation
import Testing
@testable import DomainInterviewImplementation

/// 큐 오케스트레이션 검증 — 파일시스템은 테스트별 스크래치 디렉토리, 전송·API 는 스텁.
/// 액터의 후행 Task(시도·완주)는 구조적 대기 수단이 없어 `waitUntil`(양보 폴링, 최대 1초)로 기다린다.
struct InterviewVideoUploadQueueTests {
    /// 스텁 한 벌 + 호출 기록. 실패 주입은 남은 횟수 카운터(앞에서 N번 실패 후 성공).
    /// `directory` 를 주입하면 스텁 세트가 서로 다른 두 Harness 가 같은 큐 디렉토리를 공유한다 —
    /// 프로세스 재시작(새 actor 인스턴스가 디스크 저널만 물려받는 상황)을 재현하는 데 쓴다.
    final class Harness: @unchecked Sendable {
        let directory: URL
        let issueCalls = LockIsolated<[Int]>([])
        let putCalls = LockIsolated<[String]>([])
        let completeCalls = LockIsolated<[Int]>([])
        let completedWrapUps = LockIsolated<[InterviewVideoWrapUpSpan?]>([])
        let issueFailuresRemaining = LockIsolated(0)
        let completeFailuresRemaining = LockIsolated(0)
        let reattachIds = LockIsolated<[String]>([])
        let transferCompletions: AsyncStream<BackgroundTransferCompletion>.Continuation
        let queue: VideoUploadQueueActor

        init(
            directory: URL = FileManager.default.temporaryDirectory
                .appendingPathComponent("upload-queue-tests-\(UUID().uuidString)", isDirectory: true),
            now: @escaping @Sendable () -> Date = { Date(timeIntervalSince1970: 1_000_000) }
        ) {
            self.directory = directory
            let (stream, continuation) = AsyncStream.makeStream(
                of: BackgroundTransferCompletion.self, bufferingPolicy: .unbounded
            )
            transferCompletions = continuation
            var interview = InterviewClient.testValue
            interview.videoUploadURL = { [issueCalls, issueFailuresRemaining] sessionId in
                issueCalls.withValue { $0.append(sessionId) }
                let shouldFail = issueFailuresRemaining.withValue { remaining in
                    guard remaining > 0 else { return false }
                    remaining -= 1
                    return true
                }
                if shouldFail { throw NetworkError.invalidResponse }
                return InterviewVideoUploadTarget(
                    uploadUrl: "https://s3.test/\(sessionId)", contentType: "video/mp4", expiresInSeconds: 600
                )
            }
            interview.completeVideoUpload = { [completeCalls, completedWrapUps, completeFailuresRemaining] sessionId, wrapUp in
                let shouldFail = completeFailuresRemaining.withValue { remaining in
                    guard remaining > 0 else { return false }
                    remaining -= 1
                    return true
                }
                if shouldFail { throw NetworkError.invalidResponse }
                completeCalls.withValue { $0.append(sessionId) }
                completedWrapUps.withValue { $0.append(wrapUp) }
            }
            let transfer = BackgroundTransferClient(
                enqueuePut: { [putCalls] id, _, _, _ in putCalls.withValue { $0.append(id) } },
                completions: { stream },
                reattach: { [reattachIds] in reattachIds.value },
                attachBackgroundEventsCompletionHandler: { _ in }
            )
            queue = VideoUploadQueueActor(directory: directory, interview: interview, transfer: transfer, now: now)
        }

        /// enqueue 입력용 가짜 녹화 파일 — 스크래치 밖(임시 루트)에 만들어 이동을 실제로 검증한다.
        func makeRecordingFile() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("recording-\(UUID().uuidString).mp4")
            try Data("video".utf8).write(to: url)
            return url
        }

        func storedFileURL(_ sessionId: Int) -> URL {
            directory.appendingPathComponent("\(sessionId).mp4")
        }

        func waitUntil(
            _ comment: Comment,
            _ condition: @escaping @Sendable () async -> Bool
        ) async throws {
            for _ in 0..<200 {
                if await condition() { return }
                try await Task.sleep(nanoseconds: 5_000_000)
            }
            Issue.record("대기 시간 초과: \(comment)")
        }
    }

    @Test("enqueue 는 파일을 큐 디렉토리로 이동하고 저널에 pending 으로 기록한 뒤 발급→PUT 등록까지 이어간다")
    func enqueueMovesFileAndStartsUpload() async throws {
        let harness = Harness()
        let source = try harness.makeRecordingFile()

        await harness.queue.enqueue(
            sessionId: 7, fileURL: source,
            wrapUp: InterviewVideoWrapUpSpan(wrapUpStartSec: 500, wrapUpEndSec: 512)
        )

        // enqueue 반환 시점 보장분 — 파일 이동 + 저널(pending).
        #expect(!FileManager.default.fileExists(atPath: source.path))
        #expect(FileManager.default.fileExists(atPath: harness.storedFileURL(7).path))
        let entries = await harness.queue.entriesSnapshot()
        #expect(entries.map(\.sessionId) == [7])
        #expect(entries.first?.stage == .pending)
        // 후행 Task 몫 — 발급 → PUT 등록.
        try await harness.waitUntil("발급·PUT 등록") {
            harness.issueCalls.value == [7] && harness.putCalls.value == ["7"]
        }
    }

    @Test("PUT 완료 이벤트가 오면 completing 으로 승격해 complete(wrapUp 동봉)를 부르고 저널·파일을 정리한다")
    func putCompletionDrivesCompleteAndCleanup() async throws {
        let harness = Harness()
        let source = try harness.makeRecordingFile()
        await harness.queue.enqueue(
            sessionId: 7, fileURL: source,
            wrapUp: InterviewVideoWrapUpSpan(wrapUpStartSec: 500, wrapUpEndSec: 512)
        )
        try await harness.waitUntil("PUT 등록") { harness.putCalls.value == ["7"] }

        harness.transferCompletions.yield(.completed(id: "7"))

        try await harness.waitUntil("complete 호출") { harness.completeCalls.value == [7] }
        #expect(harness.completedWrapUps.value == [InterviewVideoWrapUpSpan(wrapUpStartSec: 500, wrapUpEndSec: 512)])
        try await harness.waitUntil("정리") {
            // `&&` 의 rhs 는 autoclosure(sync)라 await 를 못 품는다 — guard 로 편다.
            guard !FileManager.default.fileExists(atPath: harness.storedFileURL(7).path) else { return false }
            return await harness.queue.entriesSnapshot().isEmpty
        }
    }

    @Test("같은 sessionId 재접수는 무시한다 — 늦은 중복 종료 통보가 업로드를 재시작하지 못한다")
    func duplicateEnqueueIsIgnored() async throws {
        let harness = Harness()
        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("첫 발급") { harness.issueCalls.value == [7] }

        let second = try harness.makeRecordingFile()
        await harness.queue.enqueue(sessionId: 7, fileURL: second, wrapUp: nil)

        let entries = await harness.queue.entriesSnapshot()
        #expect(entries.count == 1)
        #expect(harness.issueCalls.value == [7])   // 두 번째 발급 없음
        #expect(FileManager.default.fileExists(atPath: second.path))   // 두 번째 파일은 손대지 않는다
    }

    @Test("wrapUp 이 nil 이면 complete 도 nil 로 보낸다 — 바디 생략 경로")
    func nilWrapUpRoundTrips() async throws {
        let harness = Harness()
        await harness.queue.enqueue(sessionId: 9, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("PUT 등록") { harness.putCalls.value == ["9"] }

        harness.transferCompletions.yield(.completed(id: "9"))

        try await harness.waitUntil("complete 호출") { harness.completeCalls.value == [9] }
        #expect(harness.completedWrapUps.value == [nil])
    }

    @Test("발급 실패는 즉시 1회만 재시도하고 파킹한다 — 세 번째 시도는 없다")
    func issueFailureRetriesOnceThenParks() async throws {
        let harness = Harness()
        harness.issueFailuresRemaining.setValue(2)   // 1차·재시도 모두 실패

        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)

        try await harness.waitUntil("발급 2회(1차+즉시 재시도)") { harness.issueCalls.value == [7, 7] }
        try await Task.sleep(nanoseconds: 50_000_000)   // 추가 시도가 없음을 잠깐 관찰
        #expect(harness.issueCalls.value == [7, 7])
        #expect(harness.putCalls.value.isEmpty)
        let entries = await harness.queue.entriesSnapshot()
        #expect(entries.first?.stage == .pending)   // 저널에 남아 다음 재개를 기다린다
    }

    @Test("resumePending 은 파킹된 pending 항목을 발급부터 재시작한다")
    func resumeRetriesParkedEntry() async throws {
        let harness = Harness()
        harness.issueFailuresRemaining.setValue(2)
        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("파킹") { harness.issueCalls.value == [7, 7] }

        await harness.queue.resumePending()

        try await harness.waitUntil("재개 발급") { harness.issueCalls.value == [7, 7, 7] }
        try await harness.waitUntil("PUT 등록") { harness.putCalls.value == ["7"] }
    }

    @Test("resumePending 은 소진된 즉시 재시도권을 되살린다 — 재개 후 또 실패해도 한 번 더 간다")
    func resumeRestoresImmediateRetryBudget() async throws {
        let harness = Harness()
        // 3회 실패 주입: 1차·즉시 재시도(파킹까지) + 재개 직후 1회 → 네 번째 발급이 성공한다.
        // 재시도권 리셋이 없으면 재개 직후 실패에서 `retryOnceOrPark` 가 거부해 네 번째가 아예 없다.
        harness.issueFailuresRemaining.setValue(3)
        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("1+1 소진") { harness.issueCalls.value == [7, 7] }
        // 파킹 확정까지 기다린다 — 발급 기록은 호출 *시작* 시점이라 이 신호만으론 재시도가 아직 진행 중일 수 있고,
        // 시도 도중에 resume 이 겹치면 되살린 재시도권이 아니라 in-flight 가드를 관측하게 된다.
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(harness.issueCalls.value == [7, 7])   // 세 번째 시도 없음 = 재시도권 소진 후 파킹 완료

        await harness.queue.resumePending()

        // 3번째(재개)는 실패하고 4번째가 성공한다 — 되살린 재시도권으로만 생기는 4번째가 리셋의 유일한 증거다.
        // 중간 상태([7,7,7])는 기다리지 않는다: 리셋이 살아 있으면 4번째까지 마이크로초라 폴링에 안 잡힌다.
        try await harness.waitUntil("되살린 재시도권으로 4번째 발급") { harness.issueCalls.value == [7, 7, 7, 7] }
        try await harness.waitUntil("PUT 등록") { harness.putCalls.value == ["7"] }
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(harness.issueCalls.value == [7, 7, 7, 7])   // 재개 뒤에도 1+1 — 다섯 번째는 없다
    }

    @Test("resumePending 은 PUT 이 데몬에 살아 있는 항목을 재등록하지 않는다")
    func resumeSkipsInFlightPut() async throws {
        let harness = Harness()
        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("PUT 등록") { harness.putCalls.value == ["7"] }
        harness.reattachIds.setValue(["7"])   // 데몬에 살아 있는 태스크로 보고

        await harness.queue.resumePending()

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(harness.issueCalls.value == [7])   // 재발급 없음 — 완료 이벤트가 잇는다
    }

    @Test("completing 항목의 재개는 발급·PUT 없이 complete 만 재시도한다")
    func resumeCompletesCompletingEntry() async throws {
        let harness = Harness()
        harness.completeFailuresRemaining.setValue(2)   // PUT 완료 후 complete 1차+재시도 실패 → completing 파킹
        await harness.queue.enqueue(
            sessionId: 7, fileURL: try harness.makeRecordingFile(),
            wrapUp: InterviewVideoWrapUpSpan(wrapUpStartSec: 1, wrapUpEndSec: 2)
        )
        try await harness.waitUntil("PUT 등록") { harness.putCalls.value == ["7"] }
        harness.transferCompletions.yield(.completed(id: "7"))
        // 파킹 판정은 stage 만으로는 이르다 — stage 는 complete 시도 *전에* 승격되므로 시도 도중에도 참이고,
        // 그때 resumePending 이 끼면 되살린 재시도권을 실패 2번째가 삼켜 아무도 complete 를 잇지 못한다.
        // 주입한 실패가 다 소진됐는지(= 1+1 을 다 썼는지)까지 봐야 재개가 결정적이다.
        try await harness.waitUntil("completing 파킹(complete 1+1 소진)") {
            guard harness.completeFailuresRemaining.value == 0 else { return false }
            return await harness.queue.entriesSnapshot().first?.stage == .completing
        }
        let issuesBefore = harness.issueCalls.value

        await harness.queue.resumePending()

        try await harness.waitUntil("complete 성공·정리") {
            guard harness.completeCalls.value == [7] else { return false }
            return await harness.queue.entriesSnapshot().isEmpty
        }
        #expect(harness.issueCalls.value == issuesBefore)   // 발급 반복 없음
    }

    @Test("72시간을 넘긴 항목은 재개 시 파일·저널을 폐기하고 시도하지 않는다")
    func resumePurgesExpiredEntries() async throws {
        let clock = LockIsolated(Date(timeIntervalSince1970: 0))
        let harness = Harness(now: { clock.value })
        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("접수") { !harness.issueCalls.value.isEmpty }
        clock.setValue(Date(timeIntervalSince1970: VideoUploadQueueActor.maxAge + 1))
        let issuesBefore = harness.issueCalls.value

        await harness.queue.resumePending()

        let entries = await harness.queue.entriesSnapshot()
        #expect(entries.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: harness.storedFileURL(7).path))
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(harness.issueCalls.value == issuesBefore)   // 폐기 항목은 시도하지 않는다
    }

    @Test("재개는 저널에 대응 항목이 없는 mp4 만 폐기한다 — 진행 중 항목의 산출물은 살아남는다")
    func resumePurgesOrphanFilesOnly() async throws {
        let harness = Harness()
        // 발급 1+1 을 모두 실패시켜 pending 으로 파킹 — 저널에 남은 «진행 중» 항목을 만든다.
        harness.issueFailuresRemaining.setValue(2)
        await harness.queue.enqueue(sessionId: 7, fileURL: try harness.makeRecordingFile(), wrapUp: nil)
        try await harness.waitUntil("파킹") { harness.issueCalls.value == [7, 7] }
        // 완주 도중(저널 제거 후 파일 삭제 전) 죽은 흔적 — 대응 항목 없는 mp4.
        let orphan = harness.storedFileURL(99)
        try Data("orphan".utf8).write(to: orphan)

        await harness.queue.resumePending()

        #expect(!FileManager.default.fileExists(atPath: orphan.path))
        #expect(FileManager.default.fileExists(atPath: harness.storedFileURL(7).path))
    }

    @Test("프로세스가 죽어도 저널은 디스크로 남는다 — 새 인스턴스의 재개가 발급부터 다시 잇는다")
    func resumeReloadsJournalFromDiskInNewInstance() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("upload-queue-tests-\(UUID().uuidString)", isDirectory: true)
        // 1세대 — 발급 1+1 이 모두 실패해 pending 으로 파킹된 채 프로세스가 끝난 상황.
        let first = Harness(directory: directory)
        first.issueFailuresRemaining.setValue(2)
        await first.queue.enqueue(sessionId: 7, fileURL: try first.makeRecordingFile(), wrapUp: nil)
        try await first.waitUntil("1세대 파킹") { first.issueCalls.value == [7, 7] }

        // 2세대 — 메모리를 하나도 물려받지 않는 새 actor + 새 스텁 한 벌. 아는 것은 디렉토리뿐이라
        // 재개하려면 저널을 디스크에서 다시 읽는 수밖에 없다(loadJournalIfNeeded 실경로).
        let second = Harness(directory: directory)
        await second.queue.resumePending()

        try await second.waitUntil("디스크 저널로 재개") {
            second.issueCalls.value == [7] && second.putCalls.value == ["7"]
        }
        let entries = await second.queue.entriesSnapshot()
        #expect(entries.map(\.sessionId) == [7])
        #expect(entries.first?.stage == .pending)
        #expect(first.issueCalls.value == [7, 7])   // 1세대 스텁은 더 불리지 않는다 = 진짜 새 인스턴스
        #expect(FileManager.default.fileExists(atPath: second.storedFileURL(7).path))   // 산출물도 함께 살아남는다
    }
}
