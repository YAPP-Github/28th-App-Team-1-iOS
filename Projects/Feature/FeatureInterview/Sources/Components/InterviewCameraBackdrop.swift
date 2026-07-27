//
//  InterviewCameraBackdrop.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import SharedDesignSystemInterface
import SwiftUI

/// 면접 화면 공통 배경 — 전면 카메라 프리뷰 자리 + 블랙 그라데이션 스크림
/// (Figma «[2] Interview_Readiness» 계열 프레임 공통 배경. 상단 514·하단 394 중 화면 안 노출부 근사).
/// 준비 화면은 상/하단 스크림 둘 다, 세션 진행 화면은 하단만 쓴다 (`showsTopScrim`).
/// 카메라 프리뷰는 아직 자리만 잡는다 — RecordingClient(A/V 캡처, docs/work/ai-interview.md §3 예정)
/// 도입 시 placeholder 를 프리뷰 레이어로 교체하는 seam.
struct InterviewCameraBackdrop: View {
    var showsTopScrim = true

    var body: some View {
        ZStack {
            // 카메라 프리뷰 placeholder — 실기기 전면 카메라 화면이 이 자리에 온다.
            Color.GrayScale.g900

            VStack(spacing: 0) {
                if showsTopScrim {
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 426)
                }
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 306)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("상/하단 스크림 (준비)") {
    InterviewCameraBackdrop()
}

#Preview("하단 스크림만 (세션)") {
    InterviewCameraBackdrop(showsTopScrim: false)
}
