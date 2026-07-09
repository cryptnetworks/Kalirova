import SwiftData
import SwiftUI

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutEntry.startedAt, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Query private var settings: [AppSettings]
    @StateObject private var viewModel = ExerciseViewModel()
    @StateObject private var healthKitService = HealthKitService()
    @State private var showingAddWorkout = false
    @State private var importError: String?
    @State private var importStatus: String?
    @State private var isImportingWorkouts = false
    @State private var importTask: Task<Void, Never>?

    private var unitSystem: UnitSystem {
        settings.first?.unitSystem ?? profiles.first?.preferredUnitSystem ?? .metric
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    HStack(spacing: 12) {
                        Button {
                            startRecentWorkoutImport()
                        } label: {
                            Label(isImportingWorkouts ? "Importing" : "Import Last 90 Days", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryKalirovaButton())
                        .disabled(isImportingWorkouts)

                        Button {
                            showingAddWorkout = true
                        } label: {
                            Label("Manual", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.large)

                    if let importError {
                        Text(importError)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.error)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    if let importStatus {
                        Text(importStatus)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    SectionHeader(title: "Today’s Workouts")

                    if workouts.isEmpty {
                        ContentUnavailableView {
                            Label("No workouts logged", systemImage: "figure.run.circle")
                        } description: {
                            Text("Import from Apple Health or add a manual workout.")
                        } actions: {
                            Button("Import Last 90 Days") {
                                startRecentWorkoutImport()
                            }
                            .buttonStyle(PrimaryKalirovaButton())
                            .disabled(isImportingWorkouts)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(workouts) { workout in
                                WorkoutSummaryRow(workout: workout, unitSystem: unitSystem)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(workout)
                                            try? modelContext.save()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(KalirovaTheme.Colors.background)
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWorkout = true
                    } label: {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView(profile: profiles.first, unitSystem: unitSystem, viewModel: viewModel)
            }
            .onDisappear {
                importTask?.cancel()
            }
        }
    }

    private var headerCard: some View {
        PremiumCard {
            HStack(spacing: 18) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(KalirovaTheme.Colors.accentPrimary)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Move data, clearly.")
                        .font(.kalirovaSectionTitle)
                        .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                    Text("Compare Apple Watch calories with Kalirova’s estimate, including heart rate, duration, and distance when available.")
                        .font(.subheadline)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func startRecentWorkoutImport() {
        guard !isImportingWorkouts else { return }
        importTask?.cancel()
        importTask = Task { await importRecentWorkouts() }
    }

    @MainActor
    private func importRecentWorkouts() async {
        isImportingWorkouts = true
        importStatus = nil
        defer {
            isImportingWorkouts = false
            importTask = nil
        }

        do {
            try await healthKitService.requestAuthorization()
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? endDate
            let imported = try await healthKitService.importedWorkouts(from: startDate, to: endDate)
            var knownWorkoutIDs = Set(workouts.map(\.id))
            var importedCount = 0
            var duplicateCount = 0

            for sample in imported {
                try Task.checkCancellation()
                let mapped = HealthKitMapping.mapWorkout(sample)
                guard !knownWorkoutIDs.contains(mapped.id) else {
                    duplicateCount += 1
                    continue
                }
                knownWorkoutIDs.insert(mapped.id)

                let estimate = viewModel.estimate(
                    kind: mapped.input.kind,
                    durationMinutes: mapped.input.durationMinutes,
                    bodyMassKg: profiles.first?.bodyMassKg,
                    averageHeartRate: mapped.input.averageHeartRate,
                    distanceMeters: mapped.input.distanceMeters,
                    perceivedEffort: nil,
                    profile: profiles.first
                )

                let workout = WorkoutEntry(
                    id: mapped.id,
                    title: mapped.input.kind.displayName,
                    startedAt: mapped.startedAt,
                    durationMinutes: mapped.input.durationMinutes,
                    kind: mapped.input.kind,
                    sourceName: mapped.sourceName,
                    deviceReportedCalories: mapped.deviceReportedCalories,
                    appEstimatedCalories: estimate.calories,
                    estimateConfidence: estimate.confidence,
                    algorithmVersion: estimate.algorithmVersion,
                    averageHeartRate: mapped.input.averageHeartRate,
                    bodyMassKg: profiles.first?.bodyMassKg,
                    distanceMeters: mapped.input.distanceMeters
                )
                modelContext.insert(workout)
                importedCount += 1
            }

            if importedCount > 0 {
                try modelContext.save()
            }
            importError = nil
            importStatus = "Imported \(importedCount) workouts. Skipped \(duplicateCount) duplicates."
        } catch is CancellationError {
            importError = nil
        } catch {
            importError = error.localizedDescription
            importStatus = nil
        }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        offsets.map { workouts[$0] }.forEach(modelContext.delete)
        try? modelContext.save()
    }
}

private struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var profile: UserProfile?
    var unitSystem: UnitSystem
    @ObservedObject var viewModel: ExerciseViewModel

    @State private var kind: WorkoutKind = .running
    @State private var title = "Workout"
    @State private var durationMinutes = 30.0
    @State private var bodyMassKg = 80.0
    @State private var bodyMassPounds = UnitConverter.pounds(fromKilograms: 80)
    @State private var averageHeartRate = 0
    @State private var distanceMeters = 0.0
    @State private var distanceMiles = 0.0
    @State private var deviceCalories = 0.0
    @State private var perceivedEffort: PerceivedEffort = .moderate
    @State private var estimate: CalorieEstimate?

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(WorkoutKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    Picker("Effort", selection: $perceivedEffort) {
                        ForEach(PerceivedEffort.allCases, id: \.self) { effort in
                            Text(effort.rawValue.capitalized).tag(effort)
                        }
                    }
                    numberField("Duration", value: $durationMinutes, unit: "min")
                    if unitSystem == .metric {
                        numberField("Body Mass", value: $bodyMassKg, unit: "kg")
                            .onChange(of: bodyMassKg) { _, newValue in
                                bodyMassPounds = UnitConverter.pounds(fromKilograms: newValue)
                            }
                        numberField("Distance", value: $distanceMeters, unit: "m")
                            .onChange(of: distanceMeters) { _, newValue in
                                distanceMiles = UnitConverter.miles(fromKilometers: newValue / 1_000)
                            }
                    } else {
                        numberField("Body Mass", value: $bodyMassPounds, unit: "lb")
                            .onChange(of: bodyMassPounds) { _, newValue in
                                bodyMassKg = UnitConverter.kilograms(fromPounds: newValue)
                            }
                        numberField("Distance", value: $distanceMiles, unit: "mi")
                            .onChange(of: distanceMiles) { _, newValue in
                                distanceMeters = UnitConverter.kilometers(fromMiles: newValue) * 1_000
                            }
                    }
                    numberField("Device Calories", value: $deviceCalories, unit: "kcal")
                    Stepper("Average HR: \(averageHeartRate == 0 ? "None" : "\(averageHeartRate) bpm")", value: $averageHeartRate, in: 0...220)
                }

                Section("Estimate") {
                    Button {
                        estimate = calculateEstimate()
                    } label: {
                        Label("Estimate Calories", systemImage: "flame")
                    }

                    if let estimate {
                        SummaryRow(label: "App Estimated Calories", value: estimate.calories.kcalText)
                        SummaryRow(label: "Device Reported Calories", value: deviceCalories > 0 ? deviceCalories.kcalText : "Not provided")
                        SummaryRow(label: "Confidence", value: estimate.confidence.rawValue.capitalized)
                        SummaryRow(label: "Algorithm", value: estimate.algorithmVersion)
                    }
                }
            }
            .navigationTitle("Add Workout")
            .onAppear {
                bodyMassKg = profile?.bodyMassKg ?? bodyMassKg
                bodyMassPounds = UnitConverter.pounds(fromKilograms: bodyMassKg)
                distanceMiles = UnitConverter.miles(fromKilometers: distanceMeters / 1_000)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                        dismiss()
                    }
                }
            }
        }
    }

    private func numberField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        LabeledContent(label) {
            HStack {
                TextField(unit, value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text(unit)
                    .foregroundStyle(KalirovaTheme.Colors.textSecondary)
            }
        }
    }

    private func calculateEstimate() -> CalorieEstimate {
        viewModel.estimate(
            kind: kind,
            durationMinutes: durationMinutes,
            bodyMassKg: bodyMassKg > 0 ? bodyMassKg : nil,
            averageHeartRate: averageHeartRate > 0 ? averageHeartRate : nil,
            distanceMeters: distanceMeters > 0 ? distanceMeters : nil,
            perceivedEffort: perceivedEffort,
            profile: profile
        )
    }

    private func saveWorkout() {
        let finalEstimate = estimate ?? calculateEstimate()
        let workout = WorkoutEntry(
            title: title.isEmpty ? kind.displayName : title,
            durationMinutes: durationMinutes,
            kind: kind,
            sourceName: "Manual",
            deviceReportedCalories: deviceCalories > 0 ? deviceCalories : nil,
            appEstimatedCalories: finalEstimate.calories,
            estimateConfidence: finalEstimate.confidence,
            algorithmVersion: finalEstimate.algorithmVersion,
            averageHeartRate: averageHeartRate > 0 ? averageHeartRate : nil,
            bodyMassKg: bodyMassKg > 0 ? bodyMassKg : nil,
            distanceMeters: distanceMeters > 0 ? distanceMeters : nil,
            perceivedEffort: perceivedEffort
        )

        modelContext.insert(workout)
        try? modelContext.save()
    }
}

#Preview {
    ExerciseView()
}
