//
//  ShareSheet.swift
//  FeatureReport
//
//  Created by EunSeo on 26/07/29.
//

import SwiftUI
import UIKit

/// 시스템 공유 시트(`UIActivityViewController`) 래퍼 — SwiftUI `ShareLink` 는 버튼 형태라
/// «복사 직후 이어서 띄우기» 같은 프로그래매틱 제시가 안 돼 직접 감싼다.
/// 사용처가 늘면 `SharedCommon` 승격 후보.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
