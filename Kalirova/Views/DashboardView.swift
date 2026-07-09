import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \WorkoutEntry.startedAt, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \HealthMetricEntry.loggedAt, order: .reverse) private var metrics: [HealthMetricEntry]
    @Query private var goals: [Goal]
    @Query private var settings: [AppSettings]
    @StateObject private var viewModel = DashboardViewModel()
    @State private var period: DashboardPeriod = .day

    private var totals: DashboardTotals {
        viewModel.totals(meals: meals, workouts: workouts, metrics: metrics, period: period)
    }

    private var unitSystem: UnitSystem {
        settings.first?.unitSystem ?? .metric
    }

    private var calorieGoal: Double {
        goals.first { $0.type == .calories && $0.isActive }?.targetValue ?? 2_100
    }

    private var caloriesRemaining: Double {
        calorieGoal - totals.netCalories
    }

    private var groupedMeals: [MealDayGroup] {
        let calendar = Calendar.current
        let filteredMeals = meals.filter {
            period.contains($0.loggedAt, referenceDate: .now, calendar: calendar)
        }
        return MealDayGroup.group(filteredMeals, calendar: calendar)
    }

    private var weightMetrics: [HealthMetricEntry] {
        metrics
            .filter { $0.type == .bodyMass }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    Picker("Range", selection: $period) {
                        ForEach(DashboardPeriod.allCases) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Dashboard time range")

                    todaySummary

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricCard(title: "Nutrition", value: totals.caloriesIn.kcalText, systemImage: "fork.knife", tint: .teal)
                        MetricCard(title: "Exercise", value: totals.appCaloriesOut.kcalText, systemImage: "flame.fill", tint: .orange)
                        MetricCard(title: "Sleep", value: "\(totals.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr", systemImage: "bed.double.fill", tint: .indigo)
                        MetricCard(title: "Hydration", value: "\(totals.waterLiters.formatted(.number.precision(.fractionLength(1)))) L", systemImage: "drop.fill", tint: .blue)
                    }

                    MacroPanel(protein: totals.protein, carbohydrates: totals.carbohydrates, fat: totals.fat)

                    weightTrendCard

                    groupedMealsSection

                    workoutsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.largeTitle.bold())
            Text("Here’s today’s health snapshot.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var todaySummary: some View {
        PremiumCard {
            HStack(alignment: .center, spacing: 20) {
                ProgressRing(progress: min(max((calorieGoal - caloriesRemaining) / max(calorieGoal, 1), 0), 1), tint: .teal) {
                    VStack(spacing: 2) {
                        Text(abs(caloriesRemaining).formatted(.number.precision(.fractionLength(0))))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .minimumScaleFactor(0.7)
                        Text(caloriesRemaining >= 0 ? "left" : "over")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 116, height: 116)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Calories Remaining", systemImage: "flame")
                        .font(.headline)
                    Text(caloriesRemaining >= 0 ? "You’re within today’s plan." : "You’re above today’s plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        SummaryPillMini(title: "In", value: totals.caloriesIn.kcalText)
                        SummaryPillMini(title: "Out", value: totals.appCaloriesOut.kcalText)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calories remaining \(caloriesRemaining.formatted(.number.precision(.fractionLength(0))))")
    }

    private var weightTrendCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Weight Trend")
                    Spacer()
                    if let latest = totals.weightKg {
                        Text(latest.formattedWeight(unitSystem: unitSystem))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                if weightMetrics.isEmpty {
                    ContentUnavailableView("No weight entries", systemImage: "scalemass", description: Text("Add weight from Profile to see your trend."))
                        .frame(minHeight: 150)
                } else {
                    Chart(weightMetrics) { metric in
                        LineMark(
                            x: .value("Date", metric.loggedAt, unit: .day),
                            y: .value("Weight", displayWeightValue(metric.value))
                        )
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Date", metric.loggedAt, unit: .day),
                            y: .value("Weight", displayWeightValue(metric.value))
                        )
                        .foregroundStyle(.teal.opacity(0.12))
                        PointMark(
                            x: .value("Date", metric.loggedAt, unit: .day),
                            y: .value("Weight", displayWeightValue(metric.value))
                        )
                    }
                    .frame(height: 180)
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }

    private var groupedMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Meals")
            if groupedMeals.isEmpty {
                ContentUnavailableView("No meals logged today", systemImage: "fork.knife", description: Text("Add your first meal from the Meals tab."))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ForEach(groupedMeals.prefix(2)) { group in
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(group.meals) { meal in
                                MealContainerRow(meal: meal, showsDate: false)
                            }
                        }
                    }
                }
            }
        }
    }

    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Activity")
            if workouts.isEmpty {
                ContentUnavailableView("No workouts logged", systemImage: "figure.run", description: Text("Imported and manual workouts will appear here."))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ForEach(workouts.prefix(3)) { workout in
                    WorkoutSummaryRow(workout: workout, unitSystem: unitSystem)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private func displayWeightValue(_ kilograms: Double) -> Double {
        switch unitSystem {
        case .metric: kilograms
        case .imperial: UnitConverter.pounds(fromKilograms: kilograms)
        }
    }
}

struct PremiumCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct ProgressRing<Center: View>: View {
    var progress: Double
    var tint: Color
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.18), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
            center
        }
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var systemImage: String
    var tint: Color = .teal

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(value)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SummaryPillMini: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.background.opacity(0.6), in: Capsule())
    }
}

private struct MacroPanel: View {
    var protein: Double
    var carbohydrates: Double
    var fat: Double

    private var total: Double {
        max(protein + carbohydrates + fat, 1)
    }

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Nutrition")
                MacroBar(label: "Protein", value: protein, total: total, tint: .green)
                MacroBar(label: "Carbs", value: carbohydrates, total: total, tint: .blue)
                MacroBar(label: "Fat", value: fat, total: total, tint: .orange)
            }
        }
    }
}

private struct MacroBar: View {
    var label: String
    var value: Double
    var total: Double
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value.formatted(.number.precision(.fractionLength(0)))) g")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: value, total: total)
                .tint(tint)
        }
        .font(.subheadline)
    }
}

struct SectionHeader: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SummaryRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct WorkoutSummaryRow: View {
    var workout: WorkoutEntry
    var unitSystem: UnitSystem = .metric

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Label(workout.title, systemImage: "figure.run")
                        .font(.headline)
                    Spacer()
                    Text(workout.estimateConfidence.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(confidenceColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(confidenceColor)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    WorkoutValue(title: "Apple Watch", value: workout.deviceReportedCalories?.kcalText ?? "--")
                    WorkoutValue(title: "App Estimate", value: workout.appEstimatedCalories?.kcalText ?? "--")
                    WorkoutValue(title: "Duration", value: "\(workout.durationMinutes.formatted(.number.precision(.fractionLength(0)))) min")
                    WorkoutValue(title: "Heart Rate", value: workout.averageHeartRate.map { "\($0) bpm" } ?? "--")
                    if let distanceMeters = workout.distanceMeters {
                        WorkoutValue(title: "Distance", value: distanceMeters.formattedDistance(unitSystem: unitSystem))
                    }
                    if let diff = calorieDifference {
                        WorkoutValue(title: "Difference", value: diff.kcalText)
                    }
                }
            }
        }
    }

    private var calorieDifference: Double? {
        guard let device = workout.deviceReportedCalories, let app = workout.appEstimatedCalories else { return nil }
        return app - device
    }

    private var confidenceColor: Color {
        switch workout.estimateConfidence {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }
}

private struct WorkoutValue: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Double {
    var kcalText: String {
        "\(formatted(.number.precision(.fractionLength(0)))) kcal"
    }

    func formattedWeight(unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            "\(formatted(.number.precision(.fractionLength(1)))) kg"
        case .imperial:
            "\(UnitConverter.pounds(fromKilograms: self).formatted(.number.precision(.fractionLength(1)))) lb"
        }
    }

    func formattedDistance(unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            if self >= 1_000 {
                return "\((self / 1_000).formatted(.number.precision(.fractionLength(2)))) km"
            }
            return "\(formatted(.number.precision(.fractionLength(0)))) m"
        case .imperial:
            let miles = UnitConverter.miles(fromKilometers: self / 1_000)
            return "\(miles.formatted(.number.precision(.fractionLength(2)))) mi"
        }
    }
}

#Preview {
    DashboardView()
}
