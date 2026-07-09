import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \WorkoutEntry.startedAt, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \HealthMetricEntry.loggedAt, order: .reverse) private var metrics: [HealthMetricEntry]
    @Query private var goals: [Goal]
    @Query private var settings: [AppSettings]
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    private let viewModel = DashboardViewModel()
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
        let totals = self.totals
        let calorieGoal = self.calorieGoal
        let caloriesRemaining = calorieGoal - totals.netCalories

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

                    todaySummary(totals: totals, calorieGoal: calorieGoal, caloriesRemaining: caloriesRemaining)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricCard(title: "Nutrition", value: totals.caloriesIn.kcalText, systemImage: "fork.knife", tint: KalirovaTheme.Colors.nutrition)
                        MetricCard(title: "Exercise", value: totals.appCaloriesOut.kcalText, systemImage: "flame.fill", tint: KalirovaTheme.Colors.exercise)
                        MetricCard(title: "Sleep", value: "\(totals.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr", systemImage: "bed.double.fill", tint: KalirovaTheme.Colors.violet)
                        MetricCard(title: "Hydration", value: "\(totals.waterLiters.formatted(.number.precision(.fractionLength(1)))) L", systemImage: "drop.fill", tint: KalirovaTheme.Colors.accentSecondary)
                    }

                    MacroPanel(protein: totals.protein, carbohydrates: totals.carbohydrates, fat: totals.fat)

                    weightTrendCard(totals: totals)

                    groupedMealsSection

                    workoutsSection
                }
                .padding()
            }
            .background(KalirovaTheme.Colors.background)
            .navigationTitle("Home")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: KalirovaSpacing.md) {
                KalirovaBrandMark(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .kalirovaText(.navigation)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text("Track. Understand. Elevate.")
                        .font(.kalirovaCaption)
                        .foregroundStyle(KalirovaTheme.Colors.success)
                }
            }
            Text("Here’s today’s health snapshot.")
                .font(.title3)
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func todaySummary(totals: DashboardTotals, calorieGoal: Double, caloriesRemaining: Double) -> some View {
        PremiumCard {
            HStack(alignment: .center, spacing: 20) {
                ProgressRing(progress: min(max((calorieGoal - caloriesRemaining) / max(calorieGoal, 1), 0), 1), tint: KalirovaTheme.Colors.accentPrimary) {
                    VStack(spacing: 2) {
                        Text(abs(caloriesRemaining).formatted(.number.precision(.fractionLength(0))))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .minimumScaleFactor(0.7)
                        Text(caloriesRemaining >= 0 ? "left" : "over")
                            .font(.caption)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    }
                }
                .frame(width: 116, height: 116)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Calories Remaining", systemImage: "flame")
                        .font(.headline)
                    Text(caloriesRemaining >= 0 ? "You’re within today’s plan." : "You’re above today’s plan.")
                        .font(.subheadline)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
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

    private func weightTrendCard(totals: DashboardTotals) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Weight Trend")
                    Spacer()
                    if let latest = totals.weightKg {
                        Text(latest.formattedWeight(unitSystem: unitSystem))
                            .font(.headline)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
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
                        .foregroundStyle(KalirovaTheme.Colors.chartFill)
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
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
            } else {
                ForEach(groupedMeals.prefix(2)) { group in
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
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
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
            } else {
                ForEach(workouts.prefix(3)) { workout in
                    WorkoutSummaryRow(workout: workout, unitSystem: unitSystem)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let greeting: String
        if hour < 12 {
            greeting = "Good morning"
        } else if hour < 17 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }

        guard
            let username = profiles.first?.username?.trimmedUsername,
            !username.isEmpty
        else {
            return greeting
        }

        return "\(greeting), \(username)"
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
            .padding(KalirovaSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous)
                    .stroke(KalirovaTheme.Colors.cardStroke, lineWidth: 0.5)
            }
            .shadow(color: KalirovaTheme.Shadow.card, radius: 16, x: 0, y: 8)
    }
}

struct ProgressRing<Center: View>: View {
    var progress: Double
    var tint: Color
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(KalirovaTheme.Colors.controlTrack, lineWidth: 12)
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
    var tint: Color = KalirovaTheme.Colors.accentPrimary

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(value)
                    .font(.kalirovaMetric)
                    .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.kalirovaCardTitle)
                    .foregroundStyle(KalirovaTheme.Colors.textSecondary)
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
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(KalirovaTheme.Colors.surfaceSubtle.opacity(KalirovaTheme.Opacity.capsuleFill), in: Capsule())
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
                MacroBar(label: "Protein", value: protein, total: total, tint: KalirovaTheme.Colors.accentPrimary)
                MacroBar(label: "Carbs", value: carbohydrates, total: total, tint: KalirovaTheme.Colors.accentSecondary)
                MacroBar(label: "Fat", value: fat, total: total, tint: KalirovaTheme.Colors.warning)
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
                    .foregroundStyle(KalirovaTheme.Colors.textSecondary)
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
            .font(.kalirovaSectionTitle)
            .foregroundStyle(KalirovaTheme.Colors.textPrimary)
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
                        .background(confidenceColor.opacity(KalirovaTheme.Opacity.confidenceFill), in: Capsule())
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
        case .high: KalirovaTheme.Colors.success
        case .medium: KalirovaTheme.Colors.warning
        case .low: KalirovaTheme.Colors.error
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
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
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
