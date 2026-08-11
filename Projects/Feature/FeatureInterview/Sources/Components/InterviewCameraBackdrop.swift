//
//  InterviewCameraBackdrop.swift
//  FeatureInterview
//
//  Created by 서정원 on 26/07/25.
//

import DomainRecordingInterface
import SharedDesignSystemInterface
import SwiftUI

/// 면접 화면 공통 배경 — 전면 카메라 프리뷰 자리 + b900 그라데이션 스크림
/// (Figma «[2] Interview_Readiness» 계열 프레임 공통 배경. 상단 514·하단 394 중 화면 안 노출부 근사).
/// 준비 화면은 상/하단 스크림 둘 다, 세션 진행 화면은 하단만 쓴다 (`showsTopScrim`).
/// 하단은 DS `VideoOverlay(.darkClose)`, 상단은 대응 시안이 없어 화면 전용으로 남았다.
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
                    topScrim
                }
                Spacer(minLength: 0)
                // 하단은 DS `VideoOverlay(.darkClose)`(Figma «video overlay» dark/close 435:845)
                // — 2스톱 램프는 그대로 쓰고 높이만 화면 실측(306)으로 덮는다.
                VideoOverlay(.darkClose, height: Metric.bottomScrimHeight)
            }
        }
        .ignoresSafeArea()
    }

    /// 상단 스크림 — **시안에 대응 컴포넌트가 없다.** DS `VideoOverlay` 3변형은 전부 아래가
    /// 불투명한 하단 램프라 위→아래로 걷히는 이 방향이 없어서 화면 전용으로 남긴다.
    /// 색만 토큰으로 맞췄다(raw `.black` → b900 = 하단 스크림과 같은 색).
    private var topScrim: some View {
        LinearGradient(
            colors: [Color.HilitBlack.b900, .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: Metric.topScrimHeight)
        .allowsHitTesting(false)
    }

    private enum Metric {
        /// 상단 스크림 높이 — Figma 프레임 514 중 화면 안 노출부 근사.
        static let topScrimHeight: CGFloat = 426
        /// 하단 스크림 높이 — Figma 프레임 394 중 화면 안 노출부 근사(시안 dark/close 는 229).
        static let bottomScrimHeight: CGFloat = 306
    }
}

#Preview("상/하단 스크림 (준비)") {
    InterviewCameraBackdrop()
}

#Preview("하단 스크림만 (세션)") {
    InterviewCameraBackdrop(showsTopScrim: false)
}
