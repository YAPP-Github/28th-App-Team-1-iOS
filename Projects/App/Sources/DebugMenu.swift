//
//  DebugMenu.swift
//  Architecture
//
//  Dev 구성에서만 컴파일된다(#if DEV). QA·Release 바이너리엔 이 코드가 통째로 존재하지 않는다.
//  디버그 메뉴는 composition root(App 타겟)에만 둔다 — Feature 는 환경을 모른다는 규칙 유지.
//

#if DEV
import AppConfig
import AppFeature
import ComposableArchitecture
import SwiftUI

/// `AppView` 위에 떠 있는 디버그 진입 버튼 + 시트.
struct DebugMenuOverlay: ViewModifier {
    let store: StoreOf<AppFeature>
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isPresented = true
                } label: {
                    Image(systemName: "ladybug.fill")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding()
                .accessibilityIdentifier("debugMenuButton")
            }
            .sheet(isPresented: $isPresented) {
                DebugMenuView(store: store)
            }
    }
}

/// 디버그 액션 모음. 환경 표시 · 탭 점프 · 앱 데이터 삭제.
struct DebugMenuView: View {
    let store: StoreOf<AppFeature>
    @Dependency(\.appConfig) private var config
    @Environment(\.dismiss) private var dismiss
    @State private var didClear = false

    private let tabs: [AppFeature.Tab] = [.home, .users, .activity, .profile]

    var body: some View {
        NavigationStack {
            List {
                Section("환경") {
                    LabeledContent("Environment", value: config.environment.rawValue)
                    LabeledContent("baseURL", value: config.baseURL.absoluteString)
                }

                Section("탭 점프") {
                    ForEach(tabs, id: \.rawValue) { tab in
                        Button(tab.rawValue.capitalized) {
                            store.send(.binding(.set(\.selectedTab, tab)))
                            dismiss()
                        }
                    }
                }

                Section("데이터") {
                    Button("앱 데이터 전체 삭제", role: .destructive) {
                        DebugActions.clearAppData()
                        didClear = true
                    }
                    if didClear {
                        Text("UserDefaults · URLCache · Caches 삭제됨. 앱 재실행을 권장합니다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("폼 자동입력 등 화면 내부 디버그 훅은 각 Feature 의 협조가 필요해 후속 작업으로 분리됨.")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("🛠 Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

/// 부수효과 모음 — UI 와 분리해 테스트·재사용 가능하게.
enum DebugActions {
    static func clearAppData() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        URLCache.shared.removeAllCachedResponses()

        let fm = FileManager.default
        if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let contents = (try? fm.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil)) ?? []
            for item in contents {
                try? fm.removeItem(at: item)
            }
        }
    }
}
#endif
