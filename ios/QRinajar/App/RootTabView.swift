import SwiftUI

struct RootTabView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppColorSchemeStorage private var appearance
    @State private var showWelcome = false

    var body: some View {
        CreateFlowView()
            .preferredColorScheme(appearance.colorScheme)
            .onAppear {
                if !hasSeenWelcome { showWelcome = true }
            }
            .fullScreenCover(isPresented: $showWelcome) {
                WelcomeView(isPresented: $showWelcome)
                    .preferredColorScheme(appearance.colorScheme)
                    .onDisappear { hasSeenWelcome = true }
            }
    }
}
