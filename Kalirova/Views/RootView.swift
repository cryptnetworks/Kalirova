import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
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
}
