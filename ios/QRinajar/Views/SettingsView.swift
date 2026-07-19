import SwiftUI

struct SettingsView: View {
    @AppColorSchemeStorage private var appearance
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppColorScheme.allCases) { s in
                        Button {
                            appearance = s
                        } label: {
                            HStack {
                                Image(systemName: s.symbol)
                                    .foregroundStyle(brandBlue)
                                    .frame(width: 24)
                                Text(s.label).foregroundStyle(.primary)
                                Spacer()
                                if appearance == s {
                                    Image(systemName: "checkmark").foregroundStyle(brandBlue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Follow System matches your device's light/dark setting automatically.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .modifier(GlassButtonStyle())
                }
            }
        }
    }
}
