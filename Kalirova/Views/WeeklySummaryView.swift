import SwiftData
import SwiftUI

struct WeeklySummaryView: View {
    @Query(sort: \MealEntry.loggedAt, order: .forward) private var meals: [MealEntry]
    @Query(sort: \WorkoutEntry.startedAt, order: .forward) private var workouts: [WorkoutEntry]
    @Query(sort: \HealthMetricEntry.loggedAt, order: .forward) private var metrics: [HealthMetricEntry]
    @Query private var goals: [Goal]
    @Query private var settings: [AppSettings]

    @State private var aiPreview: OpenAIRequestPreview?
    @State private var previewError: AppError?

    private let summaryService = SummaryService()
    private let privacyConsentService = PrivacyConsentService()

    private var days: [DailyHealthSnapshot] {
        DailySnapshotBuilder.snapshots(meals: meals, workouts: workouts, metrics: metrics, period: .week)
    }

    private var summary: WeeklySummary {
        summaryService.weeklySummary(days: days, goals: goalSnapshot)
    }

    private var goalSnapshot: GoalSnapshot {
        GoalSnapshot(
            calorieTarget: activeGoal(.calories),
            proteinTargetGrams: activeGoal(.protein),
            stepTarget: activeGoal(.steps).map(Int.init),
            waterTargetLiters: activeGoal(.water),
            sleepTargetHours: activeGoal(.sleep)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Local Summary")
                        Text(summary.narrative)
                            .font(.body)
                        Text(summary.disclaimer)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Avg Intake", value: summary.averageCaloriesIn.kcalText, systemImage: "fork.knife")
                        MetricCard(title: "Avg Burn", value: summary.averageCaloriesOut.kcalText, systemImage: "flame")
                        MetricCard(title: "Avg Protein", value: "\(summary.averageProtein.formatted(.number.precision(.fractionLength(0)))) g", systemImage: "p.circle")
                        MetricCard(title: "Adherence", value: "\(Int((summary.adherenceScore * 100).rounded()))%", systemImage: "checkmark.seal")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "AI Payload")
                        Button {
                            createAIPreview()
                        } label: {
                            Label("Preview Weekly Payload", systemImage: "doc.text.magnifyingglass")
                        }

                        if let aiPreview {
                            Text(aiPreview.purpose)
                                .font(.footnote)
                                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                            ScrollView(.horizontal) {
                                Text(aiPreview.payload)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                        }

                        if let previewError {
                            AppErrorBanner(error: previewError) {
                                self.previewError = nil
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
            .navigationTitle("Weekly Summary")
        }
    }

    private func activeGoal(_ type: GoalType) -> Double? {
        goals.first { $0.type == type && $0.isActive }?.targetValue
    }

    private func createAIPreview() {
        do {
            aiPreview = try privacyConsentService.weeklySummaryPayloadPreview(
                days: days,
                model: settings.first?.openAIModel ?? "gpt-5.5"
            )
            previewError = nil
        } catch {
            let appError = ErrorMessageMapper.map(
                error,
                fallback: .decodingFailed(context: "Weekly AI payload preview"),
                technicalContext: "Weekly summary AI payload preview"
            )
            AppErrorLogger.log(appError, source: "Weekly summary AI preview")
            previewError = appError
        }
    }
}

#Preview {
    WeeklySummaryView()
}
