import SwiftUI

struct PrimaryKalirovaButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.kalirovaButton)
            .foregroundStyle(KalirovaTheme.Colors.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KalirovaTheme.Gradients.brand, in: Capsule())
            .opacity(configuration.isPressed ? KalirovaTheme.Opacity.pressedPrimary : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryKalirovaButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.kalirovaButton)
            .foregroundStyle(KalirovaTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.thinMaterial, in: Capsule())
            .overlay {
                Capsule().stroke(KalirovaTheme.Colors.border, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? KalirovaTheme.Opacity.pressedSecondary : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct FloatingKalirovaButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            .foregroundStyle(KalirovaTheme.Colors.buttonText)
            .frame(width: 56, height: 56)
            .background(KalirovaTheme.Gradients.brand, in: Circle())
            .shadow(color: KalirovaTheme.Shadow.card, radius: 18, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
