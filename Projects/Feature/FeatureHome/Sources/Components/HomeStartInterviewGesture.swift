//
//  HomeStartInterviewGesture.swift
//  FeatureHomeImplementation
//
//  Created by EunSeo on 26/07/31.
//

import SwiftUI

/// 「밑으로 스크롤해서 면접을 시작해 보세요!」 — 시안 문구가 약속한 전환의 제스처 쪽 절반.
/// 두 phase 뷰(`HomeDefaultView`·`HomeReportView`)가 같은 판정을 쓰도록 한 곳에 둔다.
///
/// 시트를 아래로 끌면 면접 시작 화면이 올라온다 — 문구의 «밑으로» 를 시트 이동 방향으로 읽었다.
// TODO: 모션 시안 수령 후 임계값·전환 확정 (지금 값은 구현자 판단 — 시안·모션 근거 없음).
enum HomeStartInterviewGesture {
    /// 하향 드래그 임계값(pt) — 이보다 많이 내려가면 «시작» 으로 읽는다.
    /// 44(터치 최소 크기)보다 크게 잡아 스크롤·탭 흔들림과 갈라지게 했다.
    static let downwardThreshold: CGFloat = 60

    /// 임계값을 넘은 하향 드래그에서 `action` 을 부르는 제스처.
    /// `minimumDistance` 를 둬 탭이 드래그로 오인되지 않게 한다.
    static func dragDown(perform action: @escaping () -> Void) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                // 세로 우세 + 아래 방향만 — 가로 스와이프(탭 전환)를 먹지 않는다.
                guard value.translation.height > downwardThreshold,
                      value.translation.height > abs(value.translation.width) else { return }
                action()
            }
    }
}
