import SwiftUI

extension Font {
    static let kalirovaLargeMetric = Font.system(size: 44, weight: .bold, design: .rounded)
    static let kalirovaMetric = Font.system(size: 30, weight: .bold, design: .rounded)
    static let kalirovaNavigation = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let kalirovaSectionTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let kalirovaCardTitle = Font.system(.subheadline, design: .rounded).weight(.semibold)
    static let kalirovaBody = Font.system(.body, design: .rounded)
    static let kalirovaButton = Font.system(.headline, design: .rounded).weight(.semibold)
    static let kalirovaCaption = Font.system(.caption, design: .rounded)
    static let kalirovaChartLabel = Font.system(.caption2, design: .rounded).weight(.medium)
}

struct KalirovaTextStyle: ViewModifier {
    enum Style {
        case largeMetric
        case metric
        case sectionTitle
        case cardTitle
        case caption
        case body
        case navigation
        case button
        case chartLabel
    }

    var style: Style

    func body(content: Content) -> some View {
        switch style {
        case .largeMetric:
            content.font(.kalirovaLargeMetric).foregroundStyle(KalirovaTheme.Colors.textPrimary)
        case .metric:
            content.font(.kalirovaMetric).foregroundStyle(KalirovaTheme.Colors.textPrimary)
        case .sectionTitle:
            content.font(.kalirovaSectionTitle).foregroundStyle(KalirovaTheme.Colors.textPrimary)
        case .cardTitle:
            content.font(.kalirovaCardTitle).foregroundStyle(KalirovaTheme.Colors.textSecondary)
        case .caption:
            content.font(.kalirovaCaption).foregroundStyle(KalirovaTheme.Colors.textSecondary)
        case .body:
            content.font(.kalirovaBody).foregroundStyle(KalirovaTheme.Colors.textPrimary)
        case .navigation:
            content.font(.kalirovaNavigation).foregroundStyle(KalirovaTheme.Colors.textPrimary)
        case .button:
            content.font(.kalirovaButton)
        case .chartLabel:
            content.font(.kalirovaChartLabel).foregroundStyle(KalirovaTheme.Colors.textSecondary)
        }
    }
}

extension View {
    func kalirovaText(_ style: KalirovaTextStyle.Style) -> some View {
        modifier(KalirovaTextStyle(style: style))
    }
}
