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
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent") }

            MealLogView()
                .tabItem { Label("Meals", systemImage: "fork.knife") }

            ExerciseView()
                .tabItem { Label("Exercise", systemImage: "figure.run") }

            MetricsView()
                .tabItem { Label("Metrics", systemImage: "waveform.path.ecg") }

            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }

            WeeklySummaryView()
                .tabItem { Label("Summary", systemImage: "calendar.badge.clock") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
}

