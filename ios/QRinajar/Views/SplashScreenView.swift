import SwiftUI

// Shown for a couple seconds on every cold launch, before handing off to
// the real app.
struct SplashScreenView: View {
    var onFinished: () -> Void

    private let minimumDuration: Double = 2.4

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            Text("QRinajar")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Spacer()

            Link(destination: URL(string: "https://github.com/romeomont/QRinajar")!) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Text("github.com/romeomont/QRinajar")
                        .font(.footnote.weight(.medium))
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Color(.systemBackground)
                BackdropGradient()
            }
            .ignoresSafeArea()
        }
        .task {
            try? await Task.sleep(for: .seconds(minimumDuration))
            onFinished()
        }
    }
}
