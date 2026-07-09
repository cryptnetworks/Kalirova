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
                    .foregroundStyle(KalirovaTheme.Colors.deepNavy)
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
                .background(tint.opacity(0.12), in: Circle())
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
                    .foregroundStyle(KalirovaTheme.Colors.deepNavy)
                Spacer()
                KalirovaIcon.image(KalirovaIcon.ai)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            Text(message)
                .font(.kalirovaBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .kalirovaCard(material: .ultraThinMaterial)
        .background(KalirovaTheme.Colors.lavender.opacity(0.22), in: RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous))
    }
}

struct KalirovaSearchField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: KalirovaSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(KalirovaTheme.Colors.slate)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, KalirovaSpacing.lg)
        .padding(.vertical, 13)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous)
                .stroke(KalirovaTheme.Colors.softGray, lineWidth: 1)
        }
    }
}
