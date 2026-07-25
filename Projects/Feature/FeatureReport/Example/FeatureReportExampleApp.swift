//
//  FeatureReportExampleApp.swift
//  FeatureReportExample
//
//  Created by EunSeo on 26/07/25.
//

import ComposableArchitecture
import FeatureReportImplementation
import SwiftUI

@main
struct FeatureReportExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ReportView(
                store: Store(initialState: ReportFeature.State()) {
                    ReportFeature()
                }
            )
        }
    }
}
