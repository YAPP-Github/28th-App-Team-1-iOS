//
//  VideoAPISmoke.swift
//  FeatureInterviewExample
//
//  Created by 서정원 on 26/08/04.
//

import ComposableArchitecture
import CoreNetworkInterface
import DomainInterviewInterface
import DomainInterviewReportInterface
import Foundation
import SwiftUI

// 영상 API 실서버 스모크 — «서버 응답이 우리 모델로 디코딩되는가»를 liveValue 경로로 검증한다.
// curl 은 raw JSON 까지만 보므로, 이 하네스가 남은 틈(모델 디코딩·에러 매핑)을 메운다.
//
// 흐름: 세션 확보 → expiry(업로드 전 — 첫 실행이면 videoNotFound 매핑 확인) → upload-url 발급
//      → presigned PUT(더미 64KB, Content-Type 서명 일치) → complete(바디 생략) → expiry(남은 초)
//      → report(새 스키마 디코딩 요약). 실패해도 다음 스텝을 계속 진행해 한 번에 전 계약을 훑는다 —
//      단 complete 만은 PUT 성공에 건다: 실패한 업로드를 «완료» 로 확정하면 옛 객체가 유효 판정된다.
//
// 세션 선택: `HILIT_SMOKE_SESSION_ID` 환경변수가 있으면 그 세션, 없으면 reportList 의 첫 세션.
// 새 면접을 만들지 않는다(이용권 보호) — 세션이 하나도 없으면 실패 사유로 안내.
// ⚠️ PUT 은 세션당 저장 1곳을 덮어쓴다 — 실영상이 올라간 세션에는 쓰지 말 것(더미 바이트로 대체됨).
struct VideoAPISmoke: View {
    let accessToken: String

    /// 스텝 결과 한 줄 — 실패 사유를 화면에 그대로 드러내 스모크 디버깅을 돕는다 (부트스트랩과 동일 철학).
    struct StepLog: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let ok: Bool
    }

    @State private var logs: [StepLog] = []
    @State private var running = true

    var body: some View {
        NavigationStack {
            List(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(log.ok ? "✅" : "❌") \(log.title)")
                        .font(.headline)
                    Text(log.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("영상 API 스모크")
            .overlay(alignment: .bottom) {
                if running {
                    ProgressView("진행 중")
                        .padding()
                }
            }
        }
        .task { await run() }
    }

    // MARK: - 스텝 오케스트레이션

    @MainActor
    private func run() async {
        defer { running = false }

        guard saveToken() else { return }
        guard let sessionId = await resolveSessionId() else { return }

        await checkExpiry(sessionId, label: "만료 조회(업로드 전)", videoNotFoundIsExpected: true)
        guard let target = await issueUploadTarget(sessionId) else { return }
        if await putDummyVideo(to: target) {
            await completeUpload(sessionId)
        } else {
            log("업로드 완료 확정", "PUT 실패로 건너뜀 — 실패한 업로드를 확정하지 않는다", ok: false)
        }
        await checkExpiry(sessionId, label: "만료 조회(업로드 후)", videoNotFoundIsExpected: false)
        await decodeReport(sessionId)
    }

    @MainActor
    private func saveToken() -> Bool {
        let token = LiveInterviewBootstrap.normalize(accessToken)
        guard token.split(separator: ".").count == 3 else {
            log("토큰 검증", "JWT 형태(점 2개)가 아니에요 — 토큰 한 줄 전체를 복사했는지 확인", ok: false)
            return false
        }
        do {
            // 기본 TokenStore(liveValue = Keychain) — AuthorizedNetworkClient 엔진이 읽는 그 스토어 (부트스트랩과 동일).
            @Dependency(\.tokenStore) var tokenStore
            try tokenStore.save(AuthTokens(accessToken: token, refreshToken: ""))
            log("토큰 저장", "기본 TokenStore 저장 완료", ok: true)
            return true
        } catch {
            log("토큰 저장", String(describing: error), ok: false)
            return false
        }
    }

    /// 기존 세션 재사용 — 새 면접을 만들지 않는다(이용권 HELD 방지).
    @MainActor
    private func resolveSessionId() async -> Int? {
        if let raw = ProcessInfo.processInfo.environment["HILIT_SMOKE_SESSION_ID"], let forced = Int(raw) {
            log("세션 확보", "HILIT_SMOKE_SESSION_ID = \(forced)", ok: true)
            return forced
        }
        @Dependency(\.interviewClient) var interviewClient
        do {
            guard let latest = try await interviewClient.reportList().first else {
                log(
                    "세션 확보",
                    "계정에 면접 세션이 없어요 — 면접 1회 진행(짧게 하고 이탈해도 됨) 후 재시도, 또는 HILIT_SMOKE_SESSION_ID 지정",
                    ok: false
                )
                return nil
            }
            log("세션 확보", "reportList 첫 세션 \(latest.sessionId) (\(latest.jobTypeLabel ?? "직군 미상"))", ok: true)
            return latest.sessionId
        } catch {
            log("세션 확보(reportList)", String(describing: error), ok: false)
            return nil
        }
    }

    // MARK: - 영상 API 스텝

    @MainActor
    private func checkExpiry(_ sessionId: Int, label: String, videoNotFoundIsExpected: Bool) async {
        @Dependency(\.interviewReportClient) var reportClient
        do {
            let expiry = try await reportClient.videoExpiry(sessionId)
            let days = expiry.expiresInSeconds / 86_400
            log(label, "남은 \(expiry.expiresInSeconds)초(≈\(days)일) / expired \(expiry.expired)", ok: true)
        } catch let error as InterviewReportError where error == .videoNotFound {
            // 업로드 전이라면 정상 — INTERVIEW_VIDEO_NOT_FOUND → videoNotFound 매핑이 실서버로 확인된 것.
            log(label, "영상 레코드 없음(videoNotFound) — 에러 매핑 계약 확인", ok: videoNotFoundIsExpected)
        } catch {
            log(label, String(describing: error), ok: false)
        }
    }

    @MainActor
    private func issueUploadTarget(_ sessionId: Int) async -> InterviewVideoUploadTarget? {
        @Dependency(\.interviewClient) var interviewClient
        do {
            let target = try await interviewClient.videoUploadURL(sessionId)
            let host = URL(string: target.uploadUrl)?.host ?? "?"
            log("업로드 URL 발급", "contentType \(target.contentType) / 유효 \(target.expiresInSeconds)초 / host \(host)", ok: true)
            return target
        } catch {
            log("업로드 URL 발급", String(describing: error), ok: false)
            return nil
        }
    }

    /// presigned PUT — 도메인 계약 밖(S3 직행)이라 URLSession 을 직접 쓴다. 실녹화 배선(작업 B)과 무관한 계약 스모크.
    /// 반환은 성공 여부 — complete 게이트(성공한 업로드만 확정)의 판정값이다.
    @MainActor
    private func putDummyVideo(to target: InterviewVideoUploadTarget) async -> Bool {
        guard let url = URL(string: target.uploadUrl) else {
            log("S3 PUT", "uploadUrl 이 URL 로 파싱되지 않아요", ok: false)
            return false
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        // 서명에 포함된 Content-Type — 응답 값 그대로 보내지 않으면 S3 가 거부한다(계약 검증 포인트).
        request.setValue(target.contentType, forHTTPHeaderField: "Content-Type")
        do {
            let dummy = Data(count: 64 * 1_024)
            let (_, response) = try await URLSession.shared.upload(for: request, from: dummy)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if (200..<300).contains(status) {
                log("S3 PUT", "HTTP \(status) — 더미 64KB 업로드(세션 저장소 덮어씀)", ok: true)
                return true
            } else {
                log("S3 PUT", "HTTP \(status) — Content-Type 서명 불일치 또는 URL 만료 의심", ok: false)
                return false
            }
        } catch {
            log("S3 PUT", String(describing: error), ok: false)
            return false
        }
    }

    @MainActor
    private func completeUpload(_ sessionId: Int) async {
        @Dependency(\.interviewClient) var interviewClient
        do {
            // 마무리 멘트 없음 시나리오 — 바디 생략 경로. 멱등이라 재실행 안전.
            try await interviewClient.completeVideoUpload(sessionId, nil)
            log("업로드 완료 확정", "바디 생략 호출 성공", ok: true)
        } catch {
            log("업로드 완료 확정", String(describing: error), ok: false)
        }
    }

    /// 리포트 새 스키마가 실서버 응답으로 디코딩되는지 — 이 스모크의 본 목적.
    @MainActor
    private func decodeReport(_ sessionId: Int) async {
        @Dependency(\.interviewReportClient) var reportClient
        do {
            let report = try await reportClient.report(sessionId)
            var lines = ["status \(report.status.rawValue)"]
            if let headline = report.headline {
                lines.append("headline: \(headline.prefix(24))…")
            }
            lines.append("cards \(report.cards?.count ?? 0)장 / script \(report.script?.count ?? 0)문장")
            let reasons = Set((report.cards ?? []).flatMap { ($0.highlightSpans ?? []).compactMap(\.reason) })
            if !reasons.isEmpty {
                lines.append("reason: \(reasons.map(\.rawValue).sorted().joined(separator: ", "))")
            }
            let redFlagCount = (report.cards ?? []).compactMap(\.cardRedFlagNotices).flatMap { $0 }.count
            lines.append("카드 레드플래그 \(redFlagCount)건")
            if let video = report.video {
                lines.append("video url \(video.url == nil ? "nil" : "있음") / expired \(String(describing: video.expired))")
            }
            let guest = report.guestFeedback.map { "\($0.participantCount ?? 0)명" } ?? "nil(GENERATING)"
            lines.append("guestFeedback \(guest)")
            log("리포트 디코딩", lines.joined(separator: "\n"), ok: true)
        } catch {
            log("리포트 디코딩", String(describing: error), ok: false)
        }
    }

    // MARK: - 로그

    @MainActor
    private func log(_ title: String, _ detail: String, ok: Bool) {
        logs.append(StepLog(title: title, detail: detail, ok: ok))
        let flat = detail.replacingOccurrences(of: "\n", with: " / ")
        print("⛳️ [VIDEO-SMOKE] \(ok ? "✅" : "❌") \(title) — \(flat)")
    }
}
