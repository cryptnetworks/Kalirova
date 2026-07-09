import SwiftUI

struct KalirovaCardStyle: ViewModifier {
    var padding: CGFloat = KalirovaSpacing.lg
    var radius: CGFloat = KalirovaRadius.large
    var material: Material = .thinMaterial

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(material, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.32), lineWidth: 0.5)
            }
            .shadow(color: KalirovaTheme.Shadow.card, radius: 16, x: 0, y: 8)
    }
}

extension View {
    func kalirovaCard(
        padding: CGFloat = KalirovaSpacing.lg,
        radius: CGFloat = KalirovaRadius.large,
        material: Material = .thinMaterial
    ) -> some View {
        modifier(KalirovaCardStyle(padding: padding, radius: radius, material: material))
    }
}
