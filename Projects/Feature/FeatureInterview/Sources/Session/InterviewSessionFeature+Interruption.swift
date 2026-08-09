//
//  InterviewSessionFeature+Interruption.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/08/08.
//

import ComposableArchitecture
import DomainInterviewInterface
import DomainRecordingInterface
import Foundation

// @lat: [[interview#세션]]
// depends-on: [[interview#코디네이터]] — 동결 뒤 다음 상태는 코디네이터가 받는 `delegate(.interrupted)` 하나뿐이다.
// 백그라운드 동결(스펙 ②) — 카메라 캡처는 백그라운드 진입 즉시 끊기므로 «유예» 는 없다. 모든
// 백그라운드 = 세그먼트 경계다. 랩업·합성 중은 예외(이미 종료 확정) — 각각 즉시 마감·무시.
extension InterviewSessionFeature {
    func reduceSceneBackgrounded(_ state: inout State) -> Effect<Action> {
        if state.isFinishing { return .none }
        if state.isWrappingUp {
            // 멘트 청취 포기 + 즉시 마감 — 백그라운드에선 재생이 죽어 완료 이벤트가 영영 안 와
            // 세션이 랩업에 갇힌다. 서버 세션은 이미 끝났으므로(제출 응답이 종료 확정) 재개 대상이 아니다.
            state.isWrappingUp = false
            state.wrapUpSpan = state.wrapUpStartedAt.map {
                InterviewVideoWrapUpSpan(wrapUpStartSec: Double($0), wrapUpEndSec: Double(state.elapsedSeconds))
            }
            return .merge(.cancel(id: CancelID.playback), stopRecordingAndFinish(&state))
        }
        guard state.hasStarted else { return .none }

        state.isInterrupted = true
        state.isEarlyExitWarningPresented = false
        state.isExitConfirmPresented = false
        state.isSubmitting = false   // 비행 중 제출은 취소한다 — 서버 처리 여부는 재개 재동기화가 흡수(스펙 ⑥)
        state.failure = nil          // 오버레이보다 동결이 세다 — 복귀 시 resumeCheck 경로가 잇는다
        state.pendingRetry = nil
        state.toast = nil
        let sessionId = state.sessionId
        let hasRecording = state.hasRecording
        return .merge(
            .cancel(id: CancelID.clock),      // raw 축도 함께 정지 — 녹화가 없는 시간은 영상 타임라인이 아니다
            .cancel(id: CancelID.toast),
            .cancel(id: CancelID.submission),
            .cancel(id: CancelID.playback),
            // 마이크 취소는 여기 걸지 않는다 — 취소는 캡처 스트림 종료 → live `stopCapture()` → **진행 중
            // 세션 기록 폐기(파일 삭제)** 로 이어져, 아래 마감과 merge 로 나란히 두면 어느 쪽이 먼저인지
            // 미보장이다(`stopRecordingAndFinish` 가 `includingMicCapture: false` 인 것과 같은 이유).
            // 마감이 진 백그라운드는 무음 세그먼트가 되고, 전 세그먼트가 무음이면 합성이 통째로 throw 한다.
            // 대신 아래 run 이 순서대로 stopCapture 를 부르고, 그 continuation.finish 가 캡처 effect 를 끝낸다.
            .run { send in
                // 순서 계약(스펙 ②): 마감 → suspend(쌍 등록) → stopCapture. 마감이 stopCapture 보다
                // 먼저여야 진행 중 세션 오디오가 폐기되지 않는다(정상 종료의 기존 순서 계승).
                let audio = await speechClient.finishSessionAudioRecording()
                let cumulative = await recordingClient.suspendRecording(
                    audio.map { RecordingAudioSegment(fileURL: $0.fileURL, startedAtHostSeconds: $0.startedAtHostSeconds) }
                )
                await speechClient.stopCapture()
                // held 갱신 — #69 «녹화하며 갱신» 미배선이 여기서 해소된다. 토큰은 «이 프로세스가
                // 세그먼트를 들고 있다» 는 표식(스펙 ⑤). 녹화가 없던 세션은 0초 보관값을 건드리지 않는다.
                if hasRecording, let cumulative {
                    heldSessionStore.save(HeldSession(
                        sessionId: sessionId,
                        recordedSeconds: Int(cumulative.rounded()),
                        processToken: HeldSession.currentProcessToken
                    ))
                }
                // 이탈 통보는 **맨 끝**이다(2026-08-09) — 이걸 받은 코디네이터·AppFeature 가 cover 를 닫고,
                // 그 dismiss 가 이 effect 를 취소한다. 위로 올리면 세그먼트 마감·held 갱신이 중간에 잘린다.
                await send(.delegate(.interrupted))
            }
        )
    }
}
