import SwiftUI

struct KalirovaBrandMark: View {
    var size: CGFloat = 42

    var body: some View {
        Image("Kalirova_Mark_Transparent_512")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct KalirovaDashboardTile: View {
    var title: String
    var value: String
    var subtitle: String
    var icon: String
    var tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: KalirovaSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .kalirovaText(.cardTitle)
                Text(value)
                    .font(.kalirovaMetric)
                    .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .kalirovaText(.caption)
            }

            Spacer(minLength: KalirovaSpacing.sm)

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(KalirovaTheme.Opacity.iconFill), in: Circle())
                .accessibilityHidden(true)
        }
        .kalirovaCard()
        .accessibilityElement(children: .combine)
    }
}

struct KalirovaInsightCard: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: KalirovaSpacing.md) {
            HStack {
                Label(title, systemImage: "sparkles")
                    .font(.kalirovaSectionTitle)
                    .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                Spacer()
                KalirovaIcon.image(KalirovaIcon.ai)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            Text(message)
                .font(.kalirovaBody)
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .kalirovaCard(material: .ultraThinMaterial)
        .background(KalirovaTheme.Colors.subtleBrandFill, in: RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous))
    }
}

struct KalirovaSearchField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: KalirovaSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(KalirovaTheme.Colors.textMuted)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .foregroundStyle(KalirovaTheme.Colors.inputText)
        }
        .padding(.horizontal, KalirovaSpacing.lg)
        .padding(.vertical, 13)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous)
                .stroke(KalirovaTheme.Colors.border, lineWidth: 1)
        }
    }
}
