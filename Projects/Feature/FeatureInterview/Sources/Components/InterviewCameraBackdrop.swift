//
//  InterviewCameraBackdrop.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import DomainRecordingInterface
import SharedDesignSystemInterface
import SwiftUI

/// 면접 화면 공통 배경 — 전면 카메라 프리뷰 자리 + 블랙 그라데이션 스크림
/// (Figma «[2] Interview_Readiness» 계열 프레임 공통 배경. 상단 514·하단 394 중 화면 안 노출부 근사).
/// 준비 화면은 상/하단 스크림 둘 다, 세션 진행 화면은 하단만 쓴다 (`showsTopScrim`).
/// 카메라 프리뷰는 `previewHandle` 주입 — 있으면 실카메라(RecordingClient), 없으면 placeholder
/// (권한 거부·시뮬레이터·시작 전). 핸들 확보·정지는 각 화면 Reducer/코디네이터 몫.
/// 실앱에선 각 화면이 아니라 `InterviewView`(코디네이터 뷰)에 상주한다 — 화면 교체와 함께
/// 갈아끼우면 프리뷰 레이어가 재생성되며 카메라가 끊겨 보인다.
struct InterviewCameraBackdrop: View {
    var showsTopScrim = true
    /// 있으면 실카메라 프리뷰, 없으면 placeholder.
    var previewHandle: CameraPreviewHandle?

    var body: some View {
        ZStack {
            if let previewHandle {
                CameraPreviewView(handle: previewHandle)
            } else {
                // placeholder — 권한 거부·시뮬레이터에서도 화면 구도는 유지한다.
                Color.GrayScale.g900
            }

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
