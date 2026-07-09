import SwiftUI
import UIKit

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System Default"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum KalirovaTheme {
    enum Colors {
        // Semantic colors are the app-wide source of truth for UI roles.
        // Prefer these over raw brand colors so Light Mode, Dark Mode, and
        // accessibility contrast stay consistent across every screen.
        static let backgroundPrimary = Color(.systemBackground)
        static let backgroundSecondary = Color(.systemGroupedBackground)
        static let surfacePrimary = Color(.secondarySystemGroupedBackground)
        static let surfaceElevated = Color(.tertiarySystemGroupedBackground)
        static let surfaceSubtle = Color(.secondarySystemFill)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textMuted = Color(.tertiaryLabel)
        static let accentPrimary = adaptiveColor(
            light: UIColor(red: 0.043, green: 0.463, blue: 0.416, alpha: 1),
            dark: UIColor(red: 0.176, green: 0.831, blue: 0.749, alpha: 1)
        )
        static let accentSecondary = adaptiveColor(
            light: UIColor(red: 0.114, green: 0.306, blue: 0.847, alpha: 1),
            dark: UIColor(red: 0.553, green: 0.718, blue: 1, alpha: 1)
        )
        static let success = adaptiveColor(
            light: UIColor(red: 0.043, green: 0.435, blue: 0.380, alpha: 1),
            dark: UIColor(red: 0.431, green: 0.906, blue: 0.847, alpha: 1)
        )
        static let warning = adaptiveColor(
            light: UIColor(red: 0.604, green: 0.302, blue: 0, alpha: 1),
            dark: UIColor(red: 1, green: 0.820, blue: 0.541, alpha: 1)
        )
        static let error = adaptiveColor(
            light: UIColor(red: 0.706, green: 0.137, blue: 0.094, alpha: 1),
            dark: UIColor(red: 1, green: 0.706, blue: 0.671, alpha: 1)
        )
        static let border = Color(.separator)
        static let divider = Color(.separator)
        static let buttonText = adaptiveColor(
            light: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
            dark: UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        )
        static let buttonBackground = adaptiveColor(
            light: UIColor(red: 0.043, green: 0.463, blue: 0.416, alpha: 1),
            dark: UIColor(red: 0.043, green: 0.463, blue: 0.416, alpha: 1)
        )
        static let buttonBackgroundSecondary = Color(.secondarySystemGroupedBackground)
        static let inputText = Color(.label)
        static let inputPlaceholder = Color(.placeholderText)
        static let selectedText = buttonText
        static let chartFill = adaptiveColor(
            light: UIColor(red: 0.114, green: 0.306, blue: 0.847, alpha: 0.16),
            dark: UIColor(red: 0.553, green: 0.718, blue: 1, alpha: 0.22)
        )
        static let controlTrack = Color(.tertiaryLabel).opacity(KalirovaTheme.Opacity.controlTrack)
        static let cardStroke = Color(.separator).opacity(KalirovaTheme.Opacity.cardStroke)
        static let subtleBrandFill = adaptiveColor(
            light: UIColor(red: 0.929, green: 0.914, blue: 0.996, alpha: 0.34),
            dark: UIColor(red: 0.357, green: 0.263, blue: 0.604, alpha: 0.28)
        )
        static let shadow = adaptiveColor(
            light: UIColor(white: 0, alpha: 0.10),
            dark: UIColor(white: 0, alpha: 0.35)
        )

        // Backward-compatible aliases. New UI should use the semantic names above.
        static let primary = accentPrimary
        static let secondary = accentSecondary
        static let accent = Color("KalirovaViolet")
        static let text = textPrimary
        static let background = backgroundSecondary
        static let groupedBackground = backgroundSecondary
        static let cardBackground = surfacePrimary
        static let positive = success
        static let negative = error
        static let nutrition = accentPrimary
        static let exercise = accentSecondary
        static let ai = Color("KalirovaViolet")
        static let sleep = Color("KalirovaLavender")
        static let water = Color("KalirovaLightBlue")
        static let slate = textMuted
        static let charcoal = textPrimary

        // Raw brand palette. Use these for brand art and decorative accents, not body text.
        static let oceanGreen = Color("KalirovaOceanGreen")
        static let skyBlue = Color("KalirovaSkyBlue")
        static let violet = Color("KalirovaViolet")
        static let deepNavy = Color("KalirovaDeepNavy")
        static let softGray = Color("KalirovaSoftGray")
        static let mint = Color("KalirovaMint")
        static let lightBlue = Color("KalirovaLightBlue")
        static let lavender = Color("KalirovaLavender")
        static let peach = Color("KalirovaPeach")
        static let coral = Color("KalirovaCoral")

        private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            })
        }
    }

    enum Gradients {
        static let brand = LinearGradient(
            colors: [Colors.buttonBackground, Colors.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let ai = LinearGradient(
            colors: [Colors.violet, Colors.skyBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Opacity {
        static let pressedPrimary = 0.82
        static let pressedSecondary = 0.78
        static let iconFill = 0.12
        static let elevatedFill = 0.55
        static let capsuleFill = 0.60
        static let confidenceFill = 0.15
        static let selectedSecondaryText = 0.88
        static let controlTrack = 0.22
        static let cardStroke = 0.35
        static let shadow = 0.08
    }

    enum Shadow {
        static let card = Colors.shadow
    }
}

extension Color {
    static let kalirovaPrimary = KalirovaTheme.Colors.primary
    static let kalirovaSecondary = KalirovaTheme.Colors.secondary
    static let kalirovaAccent = KalirovaTheme.Colors.accent
    static let kalirovaText = KalirovaTheme.Colors.text
    static let kalirovaBackground = KalirovaTheme.Colors.background
    static let kalirovaCard = KalirovaTheme.Colors.cardBackground
    static let kalirovaPositive = KalirovaTheme.Colors.positive
    static let kalirovaNegative = KalirovaTheme.Colors.negative
    static let kalirovaWarning = KalirovaTheme.Colors.warning
    static let kalirovaNutrition = KalirovaTheme.Colors.nutrition
    static let kalirovaExercise = KalirovaTheme.Colors.exercise
    static let kalirovaAI = KalirovaTheme.Colors.ai
}
