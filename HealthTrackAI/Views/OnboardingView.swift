import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var healthKitService = HealthKitService()

    @State private var unitSystem: UnitSystem = .metric
    @State private var ageYears = 35
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -35, to: .now) ?? .now
    @State private var sex: BiologicalSex = .notSpecified
    @State private var heightCentimeters = 175.0
    @State private var heightFeet = 5.0
    @State private var heightInches = 9.0
    @State private var bodyMassKg = 80.0
    @State private var bodyMassPounds = UnitConverter.pounds(fromKilograms: 80)
    @State private var goalBodyMassKg = 75.0
    @State private var goalBodyMassPounds = UnitConverter.pounds(fromKilograms: 75)
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goalSummary = "Improve consistency"
    @State private var healthKitError: String?
    @State private var showingBMIInfo = false

    var onComplete: () -> Void

    private var bmiEstimate: BMIEstimate? {
        BMIEstimate.calculate(heightCentimeters: heightCentimeters, bodyMassKg: bodyMassKg)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Picker("Units", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases) { unitSystem in
                            Text(unitSystem.displayName).tag(unitSystem)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: unitSystem) { _, newValue in
                        syncDisplayValues(for: newValue)
                    }

                    LabeledContent("Age") {
                        TextField("Years", value: $ageYears, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .onChange(of: dateOfBirth) { _, newValue in
                            ageYears = age(from: newValue)
                        }

                    Picker("Sex", selection: $sex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { value in
                            Text(value.rawValue.displayName).tag(value)
                        }
                    }

                    if unitSystem == .metric {
                        measurementField("Height", value: $heightCentimeters, unit: "cm")
                            .onChange(of: heightCentimeters) { _, newValue in
                                let height = UnitConverter.feetAndInches(fromCentimeters: newValue)
                                heightFeet = Double(height.feet)
                                heightInches = height.inches
                            }
                        measurementField("Weight", value: $bodyMassKg, unit: "kg")
                            .onChange(of: bodyMassKg) { _, newValue in
                                bodyMassPounds = UnitConverter.pounds(fromKilograms: newValue)
                            }
                        measurementField("Goal Weight", value: $goalBodyMassKg, unit: "kg")
                            .onChange(of: goalBodyMassKg) { _, newValue in
                                goalBodyMassPounds = UnitConverter.pounds(fromKilograms: newValue)
                            }
                    } else {
                        LabeledContent("Height") {
                            HStack {
                                TextField("ft", value: $heightFeet, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                Text("ft")
                                    .foregroundStyle(.secondary)
                                TextField("in", value: $heightInches, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                Text("in")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: heightFeet) { _, _ in updateHeightFromImperial() }
                        .onChange(of: heightInches) { _, _ in updateHeightFromImperial() }

                        measurementField("Weight", value: $bodyMassPounds, unit: "lb")
                            .onChange(of: bodyMassPounds) { _, newValue in
                                bodyMassKg = UnitConverter.kilograms(fromPounds: newValue)
                            }
                        measurementField("Goal Weight", value: $goalBodyMassPounds, unit: "lb")
                            .onChange(of: goalBodyMassPounds) { _, newValue in
                                goalBodyMassKg = UnitConverter.kilograms(fromPounds: newValue)
                            }
                    }

                    LabeledContent {
                        HStack(spacing: 8) {
                            if let bmiEstimate {
                                VStack(alignment: .trailing) {
                                    Text(bmiEstimate.value.formatted(.number.precision(.fractionLength(1))))
                                        .font(.headline)
                                    Text(bmiEstimate.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Enter height and weight")
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                showingBMIInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("BMI information")
                        }
                    } label: {
                        Text("BMI")
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
            .sheet(isPresented: $showingBMIInfo) {
                BMIInfoView()
            }
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
            dateOfBirth: dateOfBirth,
            heightCentimeters: heightCentimeters,
            bodyMassKg: bodyMassKg,
            goalBodyMassKg: goalBodyMassKg,
            activityLevel: activityLevel,
            preferredUnitSystem: unitSystem,
            goalSummary: goalSummary
        )
        modelContext.insert(profile)
        modelContext.insert(AppSettings(unitSystem: unitSystem))

        [
            Goal(type: .calories, targetValue: 2_100, unit: "kcal", cadence: .daily),
            Goal(type: .protein, targetValue: 140, unit: "g", cadence: .daily),
            Goal(type: .steps, targetValue: 8_000, unit: "steps", cadence: .daily),
            Goal(type: .water, targetValue: 2.5, unit: "L", cadence: .daily),
            Goal(type: .sleep, targetValue: 7.5, unit: "hours", cadence: .daily)
        ].forEach(modelContext.insert)

        try? modelContext.save()
    }

    private func measurementField(_ label: String, value: Binding<Double>, unit: String) -> some View {
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

    private func updateHeightFromImperial() {
        heightCentimeters = UnitConverter.centimeters(fromFeet: heightFeet, inches: heightInches)
    }

    private func syncDisplayValues(for unitSystem: UnitSystem) {
        switch unitSystem {
        case .metric:
            heightCentimeters = UnitConverter.centimeters(fromFeet: heightFeet, inches: heightInches)
            bodyMassKg = UnitConverter.kilograms(fromPounds: bodyMassPounds)
            goalBodyMassKg = UnitConverter.kilograms(fromPounds: goalBodyMassPounds)
        case .imperial:
            let height = UnitConverter.feetAndInches(fromCentimeters: heightCentimeters)
            heightFeet = Double(height.feet)
            heightInches = height.inches
            bodyMassPounds = UnitConverter.pounds(fromKilograms: bodyMassKg)
            goalBodyMassPounds = UnitConverter.pounds(fromKilograms: goalBodyMassKg)
        }
    }

    private func age(from dateOfBirth: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? ageYears
    }
}

private struct BMIInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Adult BMI Categories") {
                    LabeledContent("Underweight", value: "Below 18.5")
                    LabeledContent("Healthy weight", value: "18.5-24.9")
                    LabeledContent("Overweight", value: "25.0-29.9")
                    LabeledContent("Obesity", value: "30.0 and above")
                }

                Section("About BMI") {
                    Text("BMI is a general screening tool based on height and weight. It is not a diagnosis and does not directly measure body fat, fitness, muscle mass, pregnancy, growth stage, or individual health risk.")
                }
            }
            .navigationTitle("BMI")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
