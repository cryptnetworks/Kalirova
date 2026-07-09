import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var persistenceService: PersistenceService
    @Query private var settings: [AppSettings]

    var body: some View {
        ZStack(alignment: .top) {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }

            if let startupError = persistenceService.startupError {
                AppErrorBanner(error: startupError)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(activeAppearance.colorScheme)
    }

    private var activeAppearance: AppAppearance {
        settings.first?.appearance ?? .system
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            MealLogView()
                .tabItem { Label("Meals", systemImage: "fork.knife") }

            ExerciseView()
                .tabItem { Label("Activity", systemImage: "figure.run") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            SettingsView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(KalirovaTheme.Colors.accentPrimary)
    }
}

#Preview {
    RootView()
        .environmentObject(PersistenceService())
}
