import SwiftUI

// Persisted light/dark/system preference, shared by the welcome screen and
// Settings so both edit the same @AppStorage key.
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Follow System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// A `Binding<AppColorScheme>` over the raw-string @AppStorage key, so callers
// don't each have to hand-roll the get/set bridging.
@propertyWrapper
struct AppColorSchemeStorage: DynamicProperty {
    @AppStorage("appColorScheme") private var raw: String = AppColorScheme.system.rawValue

    var wrappedValue: AppColorScheme {
        get { AppColorScheme(rawValue: raw) ?? .system }
        nonmutating set { raw = newValue.rawValue }
    }

    var projectedValue: Binding<AppColorScheme> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}
