import SwiftUI

enum KalirovaTheme {
    enum Colors {
        static let primary = Color("KalirovaOceanGreen")
        static let secondary = Color("KalirovaSkyBlue")
        static let accent = Color("KalirovaViolet")
        static let text = Color("KalirovaDeepNavy")
        static let background = Color("KalirovaLightGray")
        static let groupedBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        static let positive = Color("OceanGreen")
        static let negative = Color("KalirovaCoral")
        static let warning = Color("KalirovaPeach")
        static let nutrition = Color("KalirovaOceanGreen")
        static let exercise = Color("KalirovaSkyBlue")
        static let ai = Color("KalirovaViolet")
        static let sleep = Color("KalirovaLavender")
        static let water = Color("KalirovaLightBlue")
        static let slate = Color("KalirovaSlate")
        static let charcoal = Color("KalirovaCharcoal")

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
    }

    enum Gradients {
        static let brand = LinearGradient(
            colors: [Colors.oceanGreen, Colors.skyBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let ai = LinearGradient(
            colors: [Colors.violet, Colors.skyBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Shadow {
        static let card = Color.black.opacity(0.06)
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
