import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var healthKitService = HealthKitService()

    @State private var step: OnboardingStep = .welcome
    @State private var unitSystem: UnitSystem = .imperial
    @State private var ageYears = 35
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -35, to: .now) ?? .now
    @State private var sex: BiologicalSex = .notSpecified
    @State private var heightCentimeters = 175.0
    @State private var heightFeet = 5
    @State private var heightInches = 9
    @State private var bodyMassKg = 80.0
    @State private var bodyMassPounds = UnitConverter.pounds(fromKilograms: 80)
    @State private var goalBodyMassKg = 75.0
    @State private var goalBodyMassPounds = UnitConverter.pounds(fromKilograms: 75)
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goal: OnboardingGoal = .improveFitness
    @State private var dailyCalories = 2_100
    @State private var healthKitError: String?
    @State private var showingBMIInfo = false
    @State private var manualAgeEntry = false
    @State private var manualWeightEntry = false

    var onComplete: () -> Void

    private var bmiEstimate: BMIEstimate? {
        BMIEstimate.calculate(heightCentimeters: heightCentimeters, bodyMassKg: bodyMassKg)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step.index + 1), total: Double(OnboardingStep.allCases.count))
                    .tint(KalirovaTheme.Colors.oceanGreen)
                    .padding(.horizontal)
                    .accessibilityLabel("Onboarding progress")

                TabView(selection: $step) {
                    welcomeStep.tag(OnboardingStep.welcome)
                    goalStep.tag(OnboardingStep.goal)
                    ageStep.tag(OnboardingStep.age)
                    sexStep.tag(OnboardingStep.sex)
                    heightStep.tag(OnboardingStep.height)
                    weightStep.tag(OnboardingStep.weight)
                    activityStep.tag(OnboardingStep.activity)
                    targetWeightStep.tag(OnboardingStep.targetWeight)
                    calorieGoalStep.tag(OnboardingStep.calories)
                    healthPermissionsStep.tag(OnboardingStep.health)
                    completeStep.tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                controls
                    .padding()
                    .background(.bar)
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBMIInfo) {
                BMIInfoView()
                    .presentationDetents([.medium])
            }
        }
    }

    private var welcomeStep: some View {
        OnboardingQuestion(
            icon: "heart.text.square.fill",
            title: "Welcome to Kalirova",
            subtitle: "A private, local-first health companion for meals, activity, trends, and goals."
        ) {
            VStack(spacing: 14) {
                Label("Your health data stays on device by default.", systemImage: "lock.shield.fill")
                Label("AI requests are opt-in and previewed before sending.", systemImage: "sparkles")
                Label("You can change these choices later in Profile.", systemImage: "person.crop.circle")
            }
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var goalStep: some View {
        OnboardingQuestion(icon: "target", title: "What is your goal?", subtitle: "Choose the outcome you want Kalirova to prioritize.") {
            VStack(spacing: 12) {
                ForEach(OnboardingGoal.allCases) { option in
                    SelectableCard(
                        title: option.title,
                        subtitle: option.subtitle,
                        systemImage: option.symbol,
                        isSelected: goal == option
                    ) {
                        goal = option
                        dailyCalories = option.defaultCalories
                    }
                }
            }
        }
    }

    private var ageStep: some View {
        OnboardingQuestion(icon: "calendar", title: "How old are you?", subtitle: "Use the wheel or switch to typed entry.") {
            VStack(spacing: 16) {
                Toggle("Type manually", isOn: $manualAgeEntry)
                    .toggleStyle(.switch)

                if manualAgeEntry {
                    TextField("Age", value: $ageYears, format: .number)
                        .keyboardType(.numberPad)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
                } else {
                    Picker("Age", selection: $ageYears) {
                        ForEach(13...100, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)
                }

                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .onChange(of: dateOfBirth) { _, newValue in
                        ageYears = age(from: newValue)
                    }
            }
        }
    }

    private var sexStep: some View {
        OnboardingQuestion(icon: "person.fill.questionmark", title: "Biological sex?", subtitle: "Used only where calculations need it. You can choose not to specify.") {
            Picker("Biological sex", selection: $sex) {
                ForEach(BiologicalSex.allCases, id: \.self) { value in
                    Text(value.rawValue.displayName).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
        }
    }

    private var heightStep: some View {
        OnboardingQuestion(icon: "ruler.fill", title: "What is your height?", subtitle: "Pick a unit system and Kalirova keeps the metric value normalized.") {
            VStack(spacing: 16) {
                unitPicker

                if unitSystem == .imperial {
                    HStack(spacing: 12) {
                        Picker("Feet", selection: $heightFeet) {
                            ForEach(3...8, id: \.self) { Text("\($0) ft").tag($0) }
                        }
                        Picker("Inches", selection: $heightInches) {
                            ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)
                    .onChange(of: heightFeet) { _, _ in updateHeightFromImperial() }
                    .onChange(of: heightInches) { _, _ in updateHeightFromImperial() }
                } else {
                    Picker("Centimeters", selection: Binding(
                        get: { Int(heightCentimeters.rounded()) },
                        set: { heightCentimeters = Double($0); syncDisplayValues(for: .metric) }
                    )) {
                        ForEach(120...230, id: \.self) { Text("\($0) cm").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)
                }

                Text(heightSummary)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weightStep: some View {
        OnboardingQuestion(icon: "scalemass.fill", title: "What is your current weight?", subtitle: "Use the wheel for quick entry or type an exact number.") {
            VStack(spacing: 16) {
                Toggle("Type manually", isOn: $manualWeightEntry)
                unitPicker

                if manualWeightEntry {
                    TextField(weightUnit, value: weightBinding, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
                } else {
                    Picker("Weight", selection: wheelWeightBinding) {
                        ForEach(weightRange, id: \.self) { value in
                            Text("\(value) \(weightUnit)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)
                }

                BMICard(estimate: bmiEstimate) {
                    showingBMIInfo = true
                }
            }
        }
    }

    private var activityStep: some View {
        OnboardingQuestion(icon: "figure.walk.motion", title: "How active are you?", subtitle: "Choose the card that best matches an average week.") {
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    SelectableCard(
                        title: level.rawValue.displayName,
                        subtitle: activityDescription(for: level),
                        systemImage: activitySymbol(for: level),
                        isSelected: activityLevel == level
                    ) {
                        activityLevel = level
                    }
                }
            }
        }
    }

    private var targetWeightStep: some View {
        OnboardingQuestion(icon: "flag.checkered", title: "What is your target weight?", subtitle: "This can be adjusted anytime from Profile.") {
            VStack(spacing: 16) {
                unitPicker
                Picker("Target weight", selection: wheelGoalWeightBinding) {
                    ForEach(weightRange, id: \.self) { value in
                        Text("\(value) \(weightUnit)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                Text(goalWeightSummary)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var calorieGoalStep: some View {
        OnboardingQuestion(icon: "flame.fill", title: "Daily calorie goal?", subtitle: "Start with this estimate, then refine it as you log meals and activity.") {
            VStack(spacing: 18) {
                Text("\(dailyCalories)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("calories per day")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Stepper("Adjust calories", value: $dailyCalories, in: 1_200...4_500, step: 50)
                    .labelsHidden()
                    .accessibilityLabel("Adjust daily calories")
            }
        }
    }

    private var healthPermissionsStep: some View {
        OnboardingQuestion(icon: "heart.text.square.fill", title: "Connect Apple Health?", subtitle: "Kalirova can import workouts and health metrics only after you allow access.") {
            VStack(spacing: 16) {
                Label("Optional and controlled by Apple Health permissions.", systemImage: "checkmark.shield.fill")
                Label("You can skip now and enable it later.", systemImage: "clock")
                Button {
                    Task { await requestHealthKit() }
                } label: {
                    Label("Request Health Access", systemImage: "heart.text.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryKalirovaButton())
                .controlSize(.large)

                Text(healthKitService.authorizationStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let healthKitError {
                    Text(healthKitError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var completeStep: some View {
        OnboardingQuestion(icon: "checkmark.seal.fill", title: "You’re ready.", subtitle: "Kalirova is set up with local-first defaults.") {
            VStack(spacing: 14) {
                SummaryPill(title: goal.title, value: "\(dailyCalories) kcal", symbol: "target")
                SummaryPill(title: "Weight", value: "\(displayWeight(bodyMassKg)) now", symbol: "scalemass")
                SummaryPill(title: "Target", value: displayWeight(goalBodyMassKg), symbol: "flag")
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if step != .welcome {
                Button {
                    moveBackward()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button {
                if step == .complete {
                    saveProfile()
                    onComplete()
                } else {
                    moveForward()
                }
            } label: {
                Label(step == .complete ? "Start Kalirova" : "Continue", systemImage: step == .complete ? "checkmark" : "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryKalirovaButton())
            .controlSize(.large)
        }
    }

    private var unitPicker: some View {
        Picker("Units", selection: $unitSystem) {
            ForEach(UnitSystem.allCases) { unitSystem in
                Text(unitSystem.displayName).tag(unitSystem)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: unitSystem) { _, newValue in
            syncDisplayValues(for: newValue)
        }
    }

    private var weightBinding: Binding<Double> {
        unitSystem == .metric ? Binding(
            get: { bodyMassKg },
            set: { bodyMassKg = $0; bodyMassPounds = UnitConverter.pounds(fromKilograms: $0) }
        ) : Binding(
            get: { bodyMassPounds },
            set: { bodyMassPounds = $0; bodyMassKg = UnitConverter.kilograms(fromPounds: $0) }
        )
    }

    private var wheelWeightBinding: Binding<Int> {
        Binding(
            get: { Int(weightBinding.wrappedValue.rounded()) },
            set: { weightBinding.wrappedValue = Double($0) }
        )
    }

    private var wheelGoalWeightBinding: Binding<Int> {
        Binding(
            get: { Int((unitSystem == .metric ? goalBodyMassKg : goalBodyMassPounds).rounded()) },
            set: { value in
                if unitSystem == .metric {
                    goalBodyMassKg = Double(value)
                    goalBodyMassPounds = UnitConverter.pounds(fromKilograms: goalBodyMassKg)
                } else {
                    goalBodyMassPounds = Double(value)
                    goalBodyMassKg = UnitConverter.kilograms(fromPounds: goalBodyMassPounds)
                }
            }
        )
    }

    private var weightRange: ClosedRange<Int> {
        unitSystem == .metric ? 35...250 : 80...550
    }

    private var weightUnit: String {
        unitSystem == .metric ? "kg" : "lb"
    }

    private var heightSummary: String {
        let imperial = UnitConverter.feetAndInches(fromCentimeters: heightCentimeters)
        return "\(Int(heightCentimeters.rounded())) cm • \(imperial.feet) ft \(Int(imperial.inches.rounded())) in"
    }

    private var goalWeightSummary: String {
        "\(displayWeight(goalBodyMassKg)) target"
    }

    private func moveForward() {
        guard let next = step.next else { return }
        withOptionalAnimation { step = next }
    }

    private func moveBackward() {
        guard let previous = step.previous else { return }
        withOptionalAnimation { step = previous }
    }

    private func withOptionalAnimation(_ changes: @escaping () -> Void) {
        if reduceMotion {
            changes()
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86), changes)
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
            goalSummary: goal.title
        )
        modelContext.insert(profile)
        modelContext.insert(AppSettings(unitSystem: unitSystem))

        [
            Goal(type: .calories, targetValue: Double(dailyCalories), unit: "kcal", cadence: .daily),
            Goal(type: .protein, targetValue: 140, unit: "g", cadence: .daily),
            Goal(type: .steps, targetValue: 8_000, unit: "steps", cadence: .daily),
            Goal(type: .water, targetValue: 2.5, unit: "L", cadence: .daily),
            Goal(type: .sleep, targetValue: 7.5, unit: "hours", cadence: .daily)
        ].forEach(modelContext.insert)

        try? modelContext.save()
    }

    private func updateHeightFromImperial() {
        heightCentimeters = UnitConverter.centimeters(fromFeet: Double(heightFeet), inches: Double(heightInches))
    }

    private func syncDisplayValues(for unitSystem: UnitSystem) {
        switch unitSystem {
        case .metric:
            heightCentimeters = UnitConverter.centimeters(fromFeet: Double(heightFeet), inches: Double(heightInches))
            bodyMassKg = UnitConverter.kilograms(fromPounds: bodyMassPounds)
            goalBodyMassKg = UnitConverter.kilograms(fromPounds: goalBodyMassPounds)
        case .imperial:
            let height = UnitConverter.feetAndInches(fromCentimeters: heightCentimeters)
            heightFeet = height.feet
            heightInches = Int(height.inches.rounded())
            bodyMassPounds = UnitConverter.pounds(fromKilograms: bodyMassKg)
            goalBodyMassPounds = UnitConverter.pounds(fromKilograms: goalBodyMassKg)
        }
    }

    private func age(from dateOfBirth: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? ageYears
    }

    private func displayWeight(_ kilograms: Double) -> String {
        switch unitSystem {
        case .metric:
            return "\(kilograms.formatted(.number.precision(.fractionLength(1)))) kg"
        case .imperial:
            return "\(UnitConverter.pounds(fromKilograms: kilograms).formatted(.number.precision(.fractionLength(1)))) lb"
        }
    }

    private func activityDescription(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary: "Mostly seated days"
        case .lightlyActive: "Light walks or a few workouts"
        case .moderatelyActive: "Regular movement most days"
        case .veryActive: "Hard workouts or active work"
        case .athlete: "Structured training volume"
        }
    }

    private func activitySymbol(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary: "chair"
        case .lightlyActive: "figure.walk"
        case .moderatelyActive: "figure.run"
        case .veryActive: "figure.strengthtraining.traditional"
        case .athlete: "medal.fill"
        }
    }
}

private enum OnboardingStep: String, CaseIterable, Identifiable {
    case welcome
    case goal
    case age
    case sex
    case height
    case weight
    case activity
    case targetWeight
    case calories
    case health
    case complete

    var id: String { rawValue }
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .goal: "Goal"
        case .age: "Age"
        case .sex: "Profile"
        case .height: "Height"
        case .weight: "Weight"
        case .activity: "Activity"
        case .targetWeight: "Target"
        case .calories: "Calories"
        case .health: "Health"
        case .complete: "Complete"
        }
    }
    var next: Self? {
        let nextIndex = index + 1
        return Self.allCases.indices.contains(nextIndex) ? Self.allCases[nextIndex] : nil
    }
    var previous: Self? {
        let previousIndex = index - 1
        return Self.allCases.indices.contains(previousIndex) ? Self.allCases[previousIndex] : nil
    }
}

private enum OnboardingGoal: String, CaseIterable, Identifiable {
    case loseWeight
    case maintainWeight
    case gainWeight
    case improveFitness

    var id: String { rawValue }
    var title: String {
        switch self {
        case .loseWeight: "Lose Weight"
        case .maintainWeight: "Maintain Weight"
        case .gainWeight: "Gain Weight"
        case .improveFitness: "Improve Fitness"
        }
    }
    var subtitle: String {
        switch self {
        case .loseWeight: "Create a steady calorie deficit"
        case .maintainWeight: "Keep habits consistent"
        case .gainWeight: "Support lean mass and recovery"
        case .improveFitness: "Balance training, food, and recovery"
        }
    }
    var symbol: String {
        switch self {
        case .loseWeight: "arrow.down.forward.circle.fill"
        case .maintainWeight: "equal.circle.fill"
        case .gainWeight: "arrow.up.forward.circle.fill"
        case .improveFitness: "figure.run.circle.fill"
        }
    }
    var defaultCalories: Int {
        switch self {
        case .loseWeight: 1_850
        case .maintainWeight: 2_100
        case .gainWeight: 2_450
        case .improveFitness: 2_200
        }
    }
}

private struct OnboardingQuestion<Content: View>: View {
    var icon: String
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(KalirovaTheme.Colors.oceanGreen)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                    .kalirovaText(.navigation)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content
            }
            .padding(24)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct SelectableCard: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : KalirovaTheme.Colors.oceanGreen)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(KalirovaTheme.Gradients.brand) : AnyShapeStyle(.thinMaterial))
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct BMICard: View {
    var estimate: BMIEstimate?
    var infoAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BMI")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(estimate?.value.formatted(.number.precision(.fractionLength(1))) ?? "--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(estimate?.category ?? "Enter height and weight")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
                Spacer()
                Button(action: infoAction) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("BMI information")
            }

            ProgressView(value: bmiProgress)
                .tint(statusColor)
                .accessibilityLabel("BMI status indicator")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var bmiProgress: Double {
        guard let estimate else { return 0 }
        return min(max(estimate.value / 40, 0), 1)
    }

    private var statusColor: Color {
        guard let value = estimate?.value else { return .secondary }
        if value < 18.5 { return KalirovaTheme.Colors.skyBlue }
        if value < 25 { return KalirovaTheme.Colors.oceanGreen }
        if value < 30 { return .orange }
        return .red
    }
}

private struct SummaryPill: View {
    var title: String
    var value: String
    var symbol: String

    var body: some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.headline)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BMIInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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

private extension String {
    var displayName: String {
        split(separator: "_").joined(separator: " ").capitalized
    }
}

#Preview {
    OnboardingView {}
}
