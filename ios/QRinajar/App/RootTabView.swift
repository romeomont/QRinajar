import SwiftUI

struct RootTabView: View {
    @State private var selection = Int(ProcessInfo.processInfo.environment["QRINAJAR_TAB"] ?? "0") ?? 0
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showOnboarding = false

    var body: some View {
        TabView(selection: $selection) {
            Tab("Create", systemImage: "qrcode", value: 0) {
                CreateView()
            }
            Tab("Style", systemImage: "paintbrush", value: 1) {
                StyleView()
            }
            Tab("Export", systemImage: "square.and.arrow.up", value: 2) {
                ExportView()
            }
            Tab("Library", systemImage: "tray.full", value: 3) {
                LibraryView()
            }
        }
        .onAppear {
            if !hasOnboarded { showOnboarding = true }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .onDisappear { hasOnboarded = true }
        }
    }
}
