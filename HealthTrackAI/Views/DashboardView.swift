import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \WorkoutEntry.startedAt, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \HealthMetricEntry.loggedAt, order: .reverse) private var metrics: [HealthMetricEntry]
    @StateObject private var viewModel = DashboardViewModel()
    @State private var period: DashboardPeriod = .day

    private var totals: DashboardTotals {
        viewModel.totals(meals: meals, workouts: workouts, metrics: metrics, period: period)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Range", selection: $period) {
                        ForEach(DashboardPeriod.allCases) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Calories In", value: totals.caloriesIn.kcalText, systemImage: "fork.knife")
                        MetricCard(title: "App Burn", value: totals.appCaloriesOut.kcalText, systemImage: "flame")
                        MetricCard(title: "Device Burn", value: totals.deviceCaloriesOut.kcalText, systemImage: "applewatch")
                        MetricCard(title: "Net", value: totals.netCalories.kcalText, systemImage: "equal.circle")
                    }

                    MacroPanel(
                        protein: totals.protein,
                        carbohydrates: totals.carbohydrates,
                        fat: totals.fat
                    )

                    SectionHeader(title: "Today")

                    VStack(spacing: 10) {
                        SummaryRow(label: "Workout Minutes", value: totals.workoutMinutes.formatted(.number.precision(.fractionLength(0))))
                        SummaryRow(label: "Steps", value: totals.steps.formatted())
                        SummaryRow(label: "Water", value: "\(totals.waterLiters.formatted(.number.precision(.fractionLength(1)))) L")
                        SummaryRow(label: "Sleep", value: "\(totals.sleepHours.formatted(.number.precision(.fractionLength(1)))) hr")
                        if let weightKg = totals.weightKg {
                            SummaryRow(label: "Latest Weight", value: "\(weightKg.formatted(.number.precision(.fractionLength(1)))) kg")
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if workouts.isEmpty {
                        ContentUnavailableView("No workouts logged", systemImage: "figure.run", description: Text("Imported and manual workouts will appear here."))
                    } else {
                        SectionHeader(title: "Recent Workouts")
                        ForEach(workouts.prefix(3)) { workout in
                            WorkoutSummaryRow(workout: workout)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Macros")
            MacroBar(label: "Protein", value: protein, total: total, tint: .green)
            MacroBar(label: "Carbs", value: carbohydrates, total: total, tint: .blue)
            MacroBar(label: "Fat", value: fat, total: total, tint: .orange)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacroBar: View {
    var label: String
    var value: Double
    var total: Double
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
            .font(.headline)
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
        }
        .font(.subheadline)
    }
}

struct WorkoutSummaryRow: View {
    var workout: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(workout.title, systemImage: "figure.run")
                    .font(.headline)
                Spacer()
                Text(workout.estimateConfidence.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(confidenceColor)
            }
            SummaryRow(label: "Device Reported Calories", value: workout.deviceReportedCalories?.kcalText ?? "Not available")
            SummaryRow(label: "App Estimated Calories", value: workout.appEstimatedCalories?.kcalText ?? "Not available")
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var confidenceColor: Color {
        switch workout.estimateConfidence {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }
}

extension Double {
    var kcalText: String {
        "\(formatted(.number.precision(.fractionLength(0)))) kcal"
    }
}

#Preview {
    DashboardView()
}
