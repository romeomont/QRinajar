import SwiftUI

@main
struct QRinajarApp: App {
    @State private var design: QRDesign
    @State private var store = PresetStore()
    @State private var showSplash = true

    init() {
        let store = PresetStore()
        let last = store.loadLast()
        _design = State(initialValue: QRDesign(last ?? .factory))
        _store = State(initialValue: store)

        if ProcessInfo.processInfo.environment["QRINAJAR_SELFTEST"] != nil {
            SelfTest.run()
        }

        // Skip the splash delay for the screenshot/self-test tooling so it
        // doesn't have to pad its own wait times.
        let env = ProcessInfo.processInfo.environment
        _showSplash = State(initialValue: env["QRINAJAR_TAB"] == nil && env["QRINAJAR_SELFTEST"] == nil)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                if showSplash {
                    SplashScreenView { showSplash = false }
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: showSplash)
            .environment(design)
            .environment(store)
            .tint(brandBlue)
            .onChange(of: design.snapshot) { _, snap in
                // Auto-persist last design (mirrors web localStorage behaviour).
                store.saveLast(snap)
            }
        }
    }
}
