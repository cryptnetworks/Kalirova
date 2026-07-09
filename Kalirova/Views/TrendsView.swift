import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query(sort: \MealEntry.loggedAt, order: .forward) private var meals: [MealEntry]
    @Query(sort: \WorkoutEntry.startedAt, order: .forward) private var workouts: [WorkoutEntry]
    @Query(sort: \HealthMetricEntry.loggedAt, order: .forward) private var metrics: [HealthMetricEntry]
    @Query private var goals: [Goal]
    @Query private var settings: [AppSettings]
    @State private var period: DashboardPeriod = .week
    @State private var selectedMetric: TrendMetric = .calories
    @State private var aiPreview: OpenAIRequestPreview?
    @State private var previewError: String?

    private let summaryService = SummaryService()
    private let privacyConsentService = PrivacyConsentService()

    private var snapshots: [DailyHealthSnapshot] {
        DailySnapshotBuilder.snapshots(meals: meals, workouts: workouts, metrics: metrics, period: period)
    }

    private var summary: WeeklySummary {
        summaryService.weeklySummary(days: weekSnapshots, goals: goalSnapshot)
    }

    private var weekSnapshots: [DailyHealthSnapshot] {
        DailySnapshotBuilder.snapshots(meals: meals, workouts: workouts, metrics: metrics, period: .week)
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
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Insights")
                            .kalirovaText(.navigation)
                        Text("Trends, progress, and local summaries.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Range", selection: $period) {
                        ForEach(DashboardPeriod.allCases) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(TrendMetric.allCases) { metric in
                            Label(metric.title, systemImage: metric.symbol).tag(metric)
                        }
                    }
                    .pickerStyle(.menu)

                    trendCard

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricCard(title: "Avg Intake", value: summary.averageCaloriesIn.kcalText, systemImage: "fork.knife", tint: KalirovaTheme.Colors.oceanGreen)
                        MetricCard(title: "Avg Burn", value: summary.averageCaloriesOut.kcalText, systemImage: "flame.fill", tint: .orange)
                        MetricCard(title: "Avg Protein", value: "\(summary.averageProtein.formatted(.number.precision(.fractionLength(0)))) g", systemImage: "p.circle.fill", tint: KalirovaTheme.Colors.oceanGreen)
                        MetricCard(title: "Adherence", value: "\(Int((summary.adherenceScore * 100).rounded()))%", systemImage: "checkmark.seal.fill", tint: KalirovaTheme.Colors.skyBlue)
                    }

                    summaryCard

                    aiPreviewCard
                }
                .padding()
            }
            .background(KalirovaTheme.Colors.background)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var trendCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(selectedMetric.title, systemImage: selectedMetric.symbol)
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Text(period.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if snapshots.isEmpty {
                    ContentUnavailableView("No trend data", systemImage: "chart.xyaxis.line", description: Text("Log meals, workouts, or metrics to build this chart."))
                        .frame(minHeight: 220)
                } else {
                    Chart(snapshots) { snapshot in
                        LineMark(
                            x: .value("Date", snapshot.date, unit: .day),
                            y: .value(selectedMetric.unit, selectedMetric.value(for: snapshot))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(KalirovaTheme.Colors.oceanGreen)
                        AreaMark(
                            x: .value("Date", snapshot.date, unit: .day),
                            y: .value(selectedMetric.unit, selectedMetric.value(for: snapshot))
                        )
                        .foregroundStyle(KalirovaTheme.Colors.skyBlue.opacity(0.12))
                        PointMark(
                            x: .value("Date", snapshot.date, unit: .day),
                            y: .value(selectedMetric.unit, selectedMetric.value(for: snapshot))
                        )
                    }
                    .frame(height: 240)
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }

    private var summaryCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Weekly Progress")
                Text(summary.narrative)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text(summary.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aiPreviewCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Privacy Preview")
                Text("Preview the weekly AI payload before anything leaves the device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    createAIPreview()
                } label: {
                    Label("Preview Weekly Payload", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if let aiPreview {
                    Text(aiPreview.purpose)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal) {
                        Text(aiPreview.payload)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                if let previewError {
                    Text(previewError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func activeGoal(_ type: GoalType) -> Double? {
        goals.first { $0.type == type && $0.isActive }?.targetValue
    }

    private func createAIPreview() {
        do {
            aiPreview = try privacyConsentService.weeklySummaryPayloadPreview(
                days: weekSnapshots,
                model: settings.first?.openAIModel ?? "gpt-5.5"
            )
            previewError = nil
        } catch {
            previewError = error.localizedDescription
        }
    }
}

struct TrendsView: View {
    var body: some View {
        InsightsView()
    }
}

enum TrendMetric: String, CaseIterable, Identifiable {
    case calories
    case protein
    case steps
    case water
    case sleep
    case weight

    var id: String { rawValue }
    var title: String {
        switch self {
        case .calories: "Calories"
        case .protein: "Protein"
        case .steps: "Steps"
        case .water: "Hydration"
        case .sleep: "Sleep"
        case .weight: "Weight"
        }
    }
    var symbol: String {
        switch self {
        case .calories: "flame.fill"
        case .protein: "p.circle.fill"
        case .steps: "shoeprints.fill"
        case .water: "drop.fill"
        case .sleep: "bed.double.fill"
        case .weight: "scalemass.fill"
        }
    }
    var unit: String {
        switch self {
        case .calories: "kcal"
        case .protein: "g"
        case .steps: "steps"
        case .water: "L"
        case .sleep: "hr"
        case .weight: "kg"
        }
    }

    func value(for snapshot: DailyHealthSnapshot) -> Double {
        switch self {
        case .calories: snapshot.nutrition.calories - snapshot.activeEnergyBurned
        case .protein: snapshot.nutrition.proteinGrams
        case .steps: Double(snapshot.steps)
        case .water: snapshot.waterLiters
        case .sleep: snapshot.sleepHours
        case .weight: snapshot.bodyMassKg ?? 0
        }
    }
}

enum DailySnapshotBuilder {
    static func snapshots(
        meals: [MealEntry],
        workouts: [WorkoutEntry],
        metrics: [HealthMetricEntry],
        period: DashboardPeriod,
        referenceDate: Date = .now
    ) -> [DailyHealthSnapshot] {
        let calendar = Calendar.current
        let relevantDates = Set(
            meals.map(\.loggedAt) + workouts.map(\.startedAt) + metrics.map(\.loggedAt)
        )
        .filter { period.contains($0, referenceDate: referenceDate, calendar: calendar) }

        return relevantDates
            .map { calendar.startOfDay(for: $0) }
            .uniqued()
            .sorted()
            .map { date in
                let dayMeals = meals.filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
                let dayWorkouts = workouts.filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
                let dayMetrics = metrics.filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }

                return DailyHealthSnapshot(
                    date: date,
                    nutrition: NutrientTotals(
                        calories: dayMeals.reduce(0) { $0 + $1.totalCalories },
                        proteinGrams: dayMeals.reduce(0) { $0 + $1.totalProtein },
                        carbohydrateGrams: dayMeals.reduce(0) { $0 + $1.totalCarbohydrates },
                        fatGrams: dayMeals.reduce(0) { $0 + $1.totalFat }
                    ),
                    activeEnergyBurned: dayWorkouts.reduce(0) { $0 + ($1.appEstimatedCalories ?? 0) },
                    workoutMinutes: dayWorkouts.reduce(0) { $0 + $1.durationMinutes },
                    steps: Int(dayMetrics.filter { $0.type == .steps }.reduce(0) { $0 + $1.value }),
                    waterLiters: dayMetrics.filter { $0.type == .water }.reduce(0) { $0 + $1.value },
                    sleepHours: dayMetrics.filter { $0.type == .sleep }.reduce(0) { $0 + $1.value },
                    bodyMassKg: dayMetrics
                        .filter { $0.type == .bodyMass }
                        .sorted { $0.loggedAt > $1.loggedAt }
                        .first?
                        .value
                )
            }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        Array(Set(self))
    }
}

#Preview {
    InsightsView()
}
