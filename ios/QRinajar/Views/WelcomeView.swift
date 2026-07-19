import SwiftUI

// Shown once, the first time the app is opened.
struct WelcomeView: View {
    @Binding var isPresented: Bool
    @AppColorSchemeStorage private var appearance

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundStyle(brandBlue)

            VStack(spacing: 6) {
                Text("You've gotten a win here.")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("QRinajar can make a QR code for you!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("Which look do you prefer?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(AppColorScheme.allCases) { s in
                    Button {
                        appearance = s
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: s.symbol)
                                .foregroundStyle(brandBlue)
                                .frame(width: 24)
                            Text(s.label).font(.body.weight(.medium))
                            Spacer()
                            if appearance == s {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(brandBlue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(appearance == s ? brandBlue.opacity(0.15) : Color.secondary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(appearance == s ? brandBlue : Color.clear, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                isPresented = false
            } label: {
                Text("Get Started").frame(maxWidth: .infinity)
            }
            .modifier(GlassProminentButtonStyle())
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(BackdropGradient())
    }
}
