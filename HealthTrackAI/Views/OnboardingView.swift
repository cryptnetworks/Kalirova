import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var healthKitService = HealthKitService()

    @State private var ageYears = 35
    @State private var sex: BiologicalSex = .notSpecified
    @State private var heightCentimeters = 175.0
    @State private var bodyMassKg = 80.0
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goalSummary = "Improve consistency"
    @State private var healthKitError: String?

    var onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Stepper("Age: \(ageYears)", value: $ageYears, in: 13...120)

                    Picker("Sex", selection: $sex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { value in
                            Text(value.rawValue.displayName).tag(value)
                        }
                    }

                    LabeledContent("Height") {
                        TextField("cm", value: $heightCentimeters, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("Weight") {
                        TextField("kg", value: $bodyMassKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Activity", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.displayName).tag(level)
                        }
                    }
                }

                Section("Goals") {
                    TextField("Primary goal", text: $goalSummary)
                    GoalSeedRow(type: .calories, value: 2_100, unit: "kcal", cadence: .daily)
                    GoalSeedRow(type: .protein, value: 140, unit: "g", cadence: .daily)
                    GoalSeedRow(type: .steps, value: 8_000, unit: "steps", cadence: .daily)
                    GoalSeedRow(type: .water, value: 2.5, unit: "L", cadence: .daily)
                    GoalSeedRow(type: .sleep, value: 7.5, unit: "hours", cadence: .daily)
                }

                Section("Privacy") {
                    Label("Health data stays on device by default.", systemImage: "lock.shield")
                    Label("ChatGPT is opt-in for each request.", systemImage: "person.crop.circle.badge.checkmark")
                    Label("Outbound AI payloads are shown before sending.", systemImage: "doc.text.magnifyingglass")
                    Text(SummaryService.wellnessDisclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple Health") {
                    Button {
                        Task { await requestHealthKit() }
                    } label: {
                        Label("Request Health Access", systemImage: "heart.text.square")
                    }
                    Text(healthKitService.authorizationStatusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let healthKitError {
                        Text(healthKitError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("HealthTrack AI")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        saveProfile()
                        onComplete()
                    }
                    .bold()
                }
            }
        }
    }

    private func requestHealthKit() async {
        do {
            try await healthKitService.requestAuthorization()
            healthKitError = nil
        } catch {
            healthKitError = error.localizedDescription
        }
    }

    private func saveProfile() {
        let profile = UserProfile(
            ageYears: ageYears,
            sex: sex,
            heightCentimeters: heightCentimeters,
            bodyMassKg: bodyMassKg,
            activityLevel: activityLevel,
            goalSummary: goalSummary
        )
        modelContext.insert(profile)
        modelContext.insert(AppSettings())

        [
            Goal(type: .calories, targetValue: 2_100, unit: "kcal", cadence: .daily),
            Goal(type: .protein, targetValue: 140, unit: "g", cadence: .daily),
            Goal(type: .steps, targetValue: 8_000, unit: "steps", cadence: .daily),
            Goal(type: .water, targetValue: 2.5, unit: "L", cadence: .daily),
            Goal(type: .sleep, targetValue: 7.5, unit: "hours", cadence: .daily)
        ].forEach(modelContext.insert)

        try? modelContext.save()
    }
}

private struct GoalSeedRow: View {
    var type: GoalType
    var value: Double
    var unit: String
    var cadence: GoalCadence

    var body: some View {
        LabeledContent(type.displayName) {
            Text("\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit) \(cadence.displayName.lowercased())")
                .foregroundStyle(.secondary)
        }
    }
}

private extension String {
    var displayName: String {
        split(separator: "_").joined(separator: " ").capitalized
    }
}

#Preview {
    OnboardingView {}
}

