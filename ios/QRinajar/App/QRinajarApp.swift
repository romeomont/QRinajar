import SwiftUI

@main
struct QRinajarApp: App {
    @State private var design: QRDesign
    @State private var store = PresetStore()

    init() {
        let store = PresetStore()
        let last = store.loadLast()
        _design = State(initialValue: QRDesign(last ?? .factory))
        _store = State(initialValue: store)

        if ProcessInfo.processInfo.environment["QRINAJAR_SELFTEST"] != nil {
            SelfTest.run()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
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
