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

struct AppErrorBanner: View {
    var error: AppError
    var onDismiss: (() -> Void)?
    var retryTitle: String?
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: KalirovaSpacing.sm) {
            HStack(alignment: .top, spacing: KalirovaSpacing.sm) {
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.title)
                        .font(.headline)
                        .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(error.message)
                        .font(.subheadline)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let recovery = error.recoverySuggestion, !recovery.isEmpty {
                        Text(recovery)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: KalirovaSpacing.sm)

                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(KalirovaTheme.Colors.textMuted)
                    .accessibilityLabel("Dismiss error")
                }
            }

            if let retryTitle, let onRetry {
                Button(action: onRetry) {
                    Label(retryTitle, systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(retryTitle)
            }

            #if DEBUG
            if let details = error.technicalDetails, !details.isEmpty {
                DisclosureGroup("Technical details") {
                    Text(details)
                        .font(.caption.monospaced())
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.footnote)
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
            }
            #endif
        }
        .padding(KalirovaSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KalirovaRadius.large, style: .continuous)
                .stroke(tint.opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var tint: Color {
        switch error.severity {
        case .info: KalirovaTheme.Colors.accentSecondary
        case .warning: KalirovaTheme.Colors.warning
        case .error: KalirovaTheme.Colors.error
        }
    }

    private var iconName: String {
        switch error.severity {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private var accessibilityLabel: String {
        [error.title, error.message, error.recoverySuggestion]
            .compactMap { $0 }
            .joined(separator: ". ")
    }
}

struct InlineValidationMessage: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(KalirovaTheme.Colors.error)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Validation error: \(message)")
    }
}

struct ErrorStateView: View {
    var error: AppError
    var retryTitle: String?
    var onRetry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: 6) {
                Text(error.message)
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                }
            }
        } actions: {
            if let retryTitle, let onRetry {
                Button(action: onRetry) {
                    Label(retryTitle, systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryKalirovaButton())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    func appErrorAlert(
        error: Binding<AppError?>,
        retryTitle: String? = nil,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        alert(
            error.wrappedValue?.title ?? "Something went wrong",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        error.wrappedValue = nil
                    }
                }
            ),
            presenting: error.wrappedValue
        ) { appError in
            if let retryTitle, let onRetry {
                Button(retryTitle) {
                    error.wrappedValue = nil
                    onRetry()
                }
            }
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        } message: { appError in
            Text([appError.message, appError.recoverySuggestion].compactMap { $0 }.joined(separator: "\n\n"))
        }
    }
}
