import SwiftData
import SwiftUI

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutEntry.startedAt, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @StateObject private var viewModel = ExerciseViewModel()
    @StateObject private var healthKitService = HealthKitService()
    @State private var showingAddWorkout = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await importRecentWorkouts() }
                    } label: {
                        Label("Import Recent Workouts", systemImage: "square.and.arrow.down")
                    }

                    if let importError {
                        Text(importError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("Workouts") {
                    ForEach(workouts) { workout in
                        WorkoutSummaryRow(workout: workout)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: deleteWorkouts)
                }
            }
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView("No workouts logged", systemImage: "figure.run")
                }
            }
            .navigationTitle("Exercise")
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
                AddWorkoutView(profile: profiles.first, viewModel: viewModel)
            }
        }
    }

    private func importRecentWorkouts() async {
        do {
            try await healthKitService.requestAuthorization()
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
            let imported = try await healthKitService.importedWorkouts(from: startDate, to: endDate)

            for sample in imported {
                let mapped = HealthKitMapping.mapWorkout(sample)
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
            }

            try? modelContext.save()
            importError = nil
        } catch {
            importError = error.localizedDescription
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
    @ObservedObject var viewModel: ExerciseViewModel

    @State private var kind: WorkoutKind = .running
    @State private var title = "Workout"
    @State private var durationMinutes = 30.0
    @State private var bodyMassKg = 80.0
    @State private var averageHeartRate = 0
    @State private var distanceMeters = 0.0
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
                    numberField("Body Mass", value: $bodyMassKg, unit: "kg")
                    numberField("Distance", value: $distanceMeters, unit: "m")
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
                    .foregroundStyle(.secondary)
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

