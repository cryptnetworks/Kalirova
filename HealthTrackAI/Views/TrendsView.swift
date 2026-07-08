import Charts
import SwiftData
import SwiftUI

struct TrendsView: View {
    @Query(sort: \MealEntry.loggedAt, order: .forward) private var meals: [MealEntry]
    @Query(sort: \WorkoutEntry.startedAt, order: .forward) private var workouts: [WorkoutEntry]
    @Query(sort: \HealthMetricEntry.loggedAt, order: .forward) private var metrics: [HealthMetricEntry]
    @State private var period: DashboardPeriod = .week

    private var snapshots: [DailyHealthSnapshot] {
        DailySnapshotBuilder.snapshots(meals: meals, workouts: workouts, metrics: metrics, period: period)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Range", selection: $period) {
                        ForEach(DashboardPeriod.allCases) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    TrendChart(title: "Calories", snapshots: snapshots, metric: .calories)
                    TrendChart(title: "Protein", snapshots: snapshots, metric: .protein)
                    TrendChart(title: "Steps", snapshots: snapshots, metric: .steps)
                    TrendChart(title: "Hydration", snapshots: snapshots, metric: .water)
                    TrendChart(title: "Sleep", snapshots: snapshots, metric: .sleep)
                    TrendChart(title: "Weight", snapshots: snapshots, metric: .weight)
                }
                .padding()
            }
            .overlay {
                if snapshots.isEmpty {
                    ContentUnavailableView("No trend data", systemImage: "chart.xyaxis.line")
                }
            }
            .navigationTitle("Trends")
        }
    }
}

private enum TrendMetric {
    case calories
    case protein
    case steps
    case water
    case sleep
    case weight

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

private struct TrendChart: View {
    var title: String
    var snapshots: [DailyHealthSnapshot]
    var metric: TrendMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
            Chart(snapshots) { snapshot in
                LineMark(
                    x: .value("Date", snapshot.date, unit: .day),
                    y: .value(metric.unit, metric.value(for: snapshot))
                )
                PointMark(
                    x: .value("Date", snapshot.date, unit: .day),
                    y: .value(metric.unit, metric.value(for: snapshot))
                )
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
    TrendsView()
}

