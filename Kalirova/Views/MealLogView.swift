import SwiftData
import SwiftUI

struct MealLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var meals: [MealEntry]
    @Query private var settings: [AppSettings]
    @State private var showingAddMeal = false

    private var groupedMeals: [MealDayGroup] {
        MealDayGroup.group(meals)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedMeals) { group in
                    Section {
                        ForEach(group.meals) { meal in
                            MealContainerRow(meal: meal, showsDate: false)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            deleteMeals(at: offsets, in: group)
                        }
                    } header: {
                        Text(group.date.formatted(date: .complete, time: .omitted))
                            .font(.headline)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(KalirovaTheme.Colors.background)
            .overlay {
                if meals.isEmpty {
                    ContentUnavailableView {
                        Label("No meals logged today", systemImage: "fork.knife.circle")
                    } description: {
                        Text("Track breakfast, lunch, dinner, snacks, or a custom meal.")
                    } actions: {
                        Button("Add Your First Meal") {
                            showingAddMeal = true
                        }
                        .buttonStyle(PrimaryKalirovaButton())
                    }
                }
            }
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMeal = true
                    } label: {
                        Label("Add Meal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(settings: settings.first)
                    .presentationDetents([.large])
            }
        }
    }

    private func deleteMeals(at offsets: IndexSet, in group: MealDayGroup) {
        offsets.map { group.meals[$0] }.forEach(modelContext.delete)
        try? modelContext.save()
    }
}

struct MealDayGroup: Identifiable {
    var date: Date
    var meals: [MealEntry]

    var id: Date { date }

    static func group(_ meals: [MealEntry], calendar: Calendar = .current) -> [MealDayGroup] {
        let groupedByDate = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.loggedAt)
        }

        return groupedByDate
            .map { date, meals in
                MealDayGroup(
                    date: date,
                    meals: meals.sorted {
                        if $0.mealType.sortOrder == $1.mealType.sortOrder {
                            return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
                        }
                        return $0.mealType.sortOrder < $1.mealType.sortOrder
                    }
                )
            }
            .sorted { $0.date > $1.date }
    }
}

struct MealContainerRow: View {
    var meal: MealEntry
    var showsDate = true

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(meal.displayTitle, systemImage: icon(for: meal.mealType))
                            .font(.headline)
                        if showsDate {
                            Text(meal.loggedAt, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    Text(meal.totalCalories.kcalText)
                        .font(.title3.weight(.semibold))
                }

                if meal.items.isEmpty {
                    Text("No food items")
                        .font(.subheadline)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(meal.items) { item in
                            FoodItemCard(item: item)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Label("\(meal.totalProtein.formatted(.number.precision(.fractionLength(0))))g protein", systemImage: "p.circle")
                    Label("\(meal.items.count) item\(meal.items.count == 1 ? "" : "s")", systemImage: "list.bullet")
                    Label(meal.source.displayName, systemImage: "tag")
                }
                .font(.caption)
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func icon(for type: MealType) -> String {
        switch type {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "takeoutbag.and.cup.and.straw.fill"
        case .custom: "fork.knife.circle.fill"
        }
    }
}

private struct FoodItemCard: View {
    var item: FoodItem

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                if !item.servingDescription.isEmpty {
                    Text(item.servingDescription)
                        .font(.caption)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }
            }
            Spacer()
            Text(item.calories.kcalText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
        }
        .padding(12)
        .background(KalirovaTheme.Colors.surfaceSubtle.opacity(KalirovaTheme.Opacity.elevatedFill), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var existingMeals: [MealEntry]

    var settings: AppSettings?

    @State private var step: MealEntryStep = .day
    @State private var loggedAt = Date()
    @State private var mealType: MealType = .breakfast
    @State private var customMealTypeName = ""
    @State private var entryMode: MealEntryMode = .ai
    @State private var restaurantName = ""
    @State private var foodName = ""
    @State private var servingDescription = ""
    @State private var mealText = ""
    @State private var manualCalories = 0.0
    @State private var manualProtein = 0.0
    @State private var manualCarbs = 0.0
    @State private var manualFat = 0.0
    @State private var manualFiber = 0.0
    @State private var manualSugar = 0.0
    @State private var manualSodium = 0.0
    @State private var localEstimate: MealNutritionEstimate?
    @State private var aiPayloadPreview: OpenAIRequestPreview?
    @State private var aiPrivacyPayload = ""
    @State private var aiEstimate: OpenAIMealAnalysis?
    @State private var selectedSource: MealSource = .manual
    @State private var selectedConfidence: EstimateConfidence = .medium
    @State private var errorMessage: String?
    @State private var showingAIPrivacyConfirmation = false
    @State private var isEstimatingWithAI = false
    @State private var aiEstimateTask: Task<Void, Never>?

    private let nutritionService = NutritionService()
    private let openAIService = OpenAIService()

    private var canSave: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (manualCalories > 0 || aiEstimate != nil || localEstimate != nil) &&
        (mealType != .custom || !customMealTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var canEstimateRestaurantMeal: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !servingDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step.index + 1), total: Double(MealEntryStep.allCases.count))
                    .tint(KalirovaTheme.Colors.accentPrimary)
                    .padding(.horizontal)

                TabView(selection: $step) {
                    dayStep.tag(MealEntryStep.day)
                    mealStep.tag(MealEntryStep.meal)
                    foodStep.tag(MealEntryStep.food)
                    reviewStep.tag(MealEntryStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack {
                    if step != .day {
                        Button {
                            if let previous = step.previous {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) { step = previous }
                            }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        if step == .review {
                            saveFoodItem()
                            dismiss()
                        } else if let next = step.next {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) { step = next }
                        }
                    } label: {
                        Label(step == .review ? "Accept" : "Continue", systemImage: step == .review ? "checkmark" : "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryKalirovaButton())
                    .disabled(step == .review && !canSave)
                }
                .controlSize(.large)
                .padding()
                .background(.bar)
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAIPrivacyConfirmation) {
                OpenAIPrivacyConfirmationSheet(
                    preview: aiPayloadPreview,
                    mealInformationPayload: aiPrivacyPayload,
                    onCancel: { showingAIPrivacyConfirmation = false },
                    onConfirm: {
                        showingAIPrivacyConfirmation = false
                        startRestaurantMealEstimate()
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        aiEstimateTask?.cancel()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                aiEstimateTask?.cancel()
            }
        }
    }

    private var dayStep: some View {
        GuidedMealStep(title: "Choose day", subtitle: "Meals are grouped by date and meal type.", symbol: "calendar") {
            DatePicker("Meal date", selection: $loggedAt, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
    }

    private var mealStep: some View {
        GuidedMealStep(title: "Choose meal", subtitle: "Add multiple food items to the same meal section.", symbol: "fork.knife") {
            VStack(spacing: 12) {
                ForEach(MealType.allCases) { type in
                    SelectableMealTypeCard(type: type, isSelected: mealType == type) {
                        mealType = type
                    }
                }
                if mealType == .custom {
                    TextField("Custom meal name", text: $customMealTypeName)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var foodStep: some View {
        GuidedMealStep(title: "Add food", subtitle: "Search with AI or enter nutrition manually. Estimates are never saved automatically.", symbol: "magnifyingglass") {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Entry mode", selection: $entryMode) {
                    ForEach(MealEntryMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if entryMode == .ai {
                    TextField("16 oz Texas Roadhouse Ribeye", text: $foodName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                    TextField("Restaurant or brand", text: $restaurantName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                    TextField("Portion or measurement", text: $servingDescription)
                        .textFieldStyle(.roundedBorder)
                    TextField("Notes or modifications", text: $mealText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        prepareAIPrivacyConfirmation()
                    } label: {
                        Label(isEstimatingWithAI ? "Estimating" : "AI Search", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryKalirovaButton())
                    .disabled(!canEstimateRestaurantMeal || isEstimatingWithAI)
                } else {
                    TextField("Two scrambled eggs", text: $foodName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Serving", text: $servingDescription)
                        .textFieldStyle(.roundedBorder)
                    nutritionEditor
                    Button {
                        applyLocalEstimate()
                    } label: {
                        Label("Estimate Locally", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(localEstimateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.error)
                }
            }
        }
    }

    private var reviewStep: some View {
        GuidedMealStep(title: "Review before saving", subtitle: "Accept, edit, or cancel. Kalirova will not save the estimate until you accept.", symbol: "checklist") {
            VStack(spacing: 16) {
                if let aiEstimate {
                    OpenAIRestaurantEstimateSummary(analysis: aiEstimate)
                    Button("Edit Nutrition") {
                        applyAIEstimate(aiEstimate)
                        entryMode = .manual
                        step = .food
                    }
                    .buttonStyle(.bordered)
                } else {
                    NutritionReviewCard(
                        name: foodName,
                        serving: savedServingDescription,
                        calories: manualCalories,
                        protein: manualProtein,
                        carbs: manualCarbs,
                        fat: manualFat,
                        confidence: selectedConfidence
                    )
                    Button("Edit") {
                        entryMode = .manual
                        step = .food
                    }
                    .buttonStyle(.bordered)
                }

                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var nutritionEditor: some View {
        VStack(spacing: 10) {
            nutritionField("Calories", value: $manualCalories, unit: "kcal")
            nutritionField("Protein", value: $manualProtein, unit: "g")
            nutritionField("Carbs", value: $manualCarbs, unit: "g")
            nutritionField("Fat", value: $manualFat, unit: "g")
        }
    }

    private var localEstimateText: String {
        [restaurantName, foodName, servingDescription, mealText]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var mealDisplayTitle: String {
        mealType == .custom ? customMealTypeName.trimmingCharacters(in: .whitespacesAndNewlines) : mealType.displayName
    }

    private func nutritionField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        LabeledContent(label) {
            HStack {
                TextField(unit, value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text(unit)
                    .foregroundStyle(KalirovaTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func applyLocalEstimate() {
        let estimate = nutritionService.parseLocalMealDescription(localEstimateText)
        localEstimate = estimate
        manualCalories = estimate.totals.calories
        manualProtein = estimate.totals.proteinGrams
        manualCarbs = estimate.totals.carbohydrateGrams
        manualFat = estimate.totals.fatGrams
        manualFiber = estimate.totals.fiberGrams
        manualSugar = estimate.totals.sugarGrams
        manualSodium = estimate.totals.sodiumMilligrams
        selectedSource = .localParser
        selectedConfidence = estimate.confidence
        step = .review
    }

    private var restaurantEstimateRequest: RestaurantMealEstimateRequest {
        RestaurantMealEstimateRequest(
            restaurantName: restaurantName.trimmingCharacters(in: .whitespacesAndNewlines),
            itemName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            portionDescription: servingDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: mealText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func prepareAIPrivacyConfirmation() {
        do {
            let request = restaurantEstimateRequest
            aiPrivacyPayload = try openAIService.previewRestaurantMealInformation(request)
            aiPayloadPreview = try openAIService.previewRestaurantMealEstimatePayload(
                request: request,
                model: settings?.openAIModel ?? "gpt-5.5"
            )
            errorMessage = nil
            showingAIPrivacyConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startRestaurantMealEstimate() {
        aiEstimateTask?.cancel()
        aiEstimateTask = Task { await estimateRestaurantMeal() }
    }

    @MainActor
    private func estimateRestaurantMeal() async {
        isEstimatingWithAI = true
        defer {
            isEstimatingWithAI = false
            aiEstimateTask = nil
        }

        do {
            let apiKey = try KeychainService.shared.loadOpenAIAPIKey()
            aiEstimate = try await openAIService.estimateRestaurantMeal(
                request: restaurantEstimateRequest,
                model: settings?.openAIModel ?? "gpt-5.5",
                apiKey: apiKey
            )
            if let aiEstimate {
                applyAIEstimate(aiEstimate)
            }
            selectedSource = .openAI
            errorMessage = nil
            step = .review
        } catch is CancellationError {
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyAIEstimate(_ analysis: OpenAIMealAnalysis) {
        manualCalories = analysis.totalCalories
        manualProtein = analysis.totalProteinGrams
        manualCarbs = analysis.totalCarbohydrateGrams
        manualFat = analysis.totalFatGrams
        manualFiber = analysis.totalFiberGrams
        manualSugar = analysis.totalSugarGrams
        manualSodium = analysis.totalSodiumMilligrams
        selectedSource = .openAI
        selectedConfidence = EstimateConfidence(rawValue: analysis.confidence) ?? .low
    }

    private func saveFoodItem() {
        let item = FoodItem(
            name: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            servingDescription: savedServingDescription,
            calories: manualCalories,
            proteinGrams: manualProtein,
            carbohydrateGrams: manualCarbs,
            fatGrams: manualFat,
            fiberGrams: manualFiber,
            sugarGrams: manualSugar,
            sodiumMilligrams: manualSodium
        )

        if let existingMeal = matchingMealContainer() {
            existingMeal.items.append(item)
            existingMeal.sourceRawValue = selectedSource.rawValue
            existingMeal.confidenceRawValue = selectedConfidence.rawValue
            if !savedNotes.isEmpty {
                existingMeal.notes = [existingMeal.notes, savedNotes]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
            }
            try? modelContext.save()
            return
        }

        let mealDate = Calendar.current.startOfDay(for: loggedAt)
        let meal = MealEntry(
            title: mealDisplayTitle,
            loggedAt: mealDate,
            mealType: mealType,
            customMealTypeName: mealType == .custom ? mealDisplayTitle : "",
            source: selectedSource,
            confidence: selectedConfidence,
            notes: savedNotes,
            items: [item]
        )

        modelContext.insert(meal)
        try? modelContext.save()
    }

    private func matchingMealContainer() -> MealEntry? {
        let calendar = Calendar.current
        let normalizedCustomName = customMealTypeName.normalizedMealKey

        return existingMeals.first { meal in
            guard calendar.isDate(meal.loggedAt, inSameDayAs: loggedAt), meal.mealType == mealType else {
                return false
            }
            guard mealType == .custom else { return true }
            return meal.customMealTypeName.normalizedMealKey == normalizedCustomName
        }
    }

    private var savedServingDescription: String {
        [restaurantName, servingDescription]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }

    private var savedNotes: String {
        var lines: [String] = []
        let trimmedRestaurant = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRestaurant.isEmpty { lines.append("Restaurant: \(trimmedRestaurant)") }
        let trimmedNotes = mealText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty { lines.append("Notes: \(trimmedNotes)") }
        if selectedSource == .openAI, let aiEstimate {
            if !aiEstimate.assumptions.isEmpty { lines.append("ChatGPT assumptions: \(aiEstimate.assumptions.joined(separator: "; "))") }
            if !aiEstimate.sourceNotes.isEmpty { lines.append("ChatGPT source notes: \(aiEstimate.sourceNotes.joined(separator: "; "))") }
            if !aiEstimate.disclaimer.isEmpty { lines.append("ChatGPT disclaimer: \(aiEstimate.disclaimer)") }
        }
        return lines.joined(separator: "\n")
    }
}

private enum MealEntryStep: String, CaseIterable, Identifiable {
    case day
    case meal
    case food
    case review

    var id: String { rawValue }
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
    var next: Self? {
        let nextIndex = index + 1
        return Self.allCases.indices.contains(nextIndex) ? Self.allCases[nextIndex] : nil
    }
    var previous: Self? {
        let previousIndex = index - 1
        return Self.allCases.indices.contains(previousIndex) ? Self.allCases[previousIndex] : nil
    }
}

private enum MealEntryMode: String, CaseIterable, Identifiable {
    case ai
    case manual

    var id: String { rawValue }
    var title: String { self == .ai ? "AI Search" : "Manual" }
    var symbol: String { self == .ai ? "sparkles" : "square.and.pencil" }
}

private struct GuidedMealStep<Content: View>: View {
    var title: String
    var subtitle: String
    var symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label(title, systemImage: symbol)
                    .kalirovaText(.navigation)
                    .labelStyle(.titleAndIcon)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                content
            }
            .padding()
        }
        .background(KalirovaTheme.Colors.background)
    }
}

private struct SelectableMealTypeCard: View {
    var type: MealType
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 32)
                Text(type.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            }
            .padding()
            .background(isSelected ? AnyShapeStyle(KalirovaTheme.Gradients.brand) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: KalirovaRadius.xlarge, style: .continuous))
            .foregroundStyle(isSelected ? KalirovaTheme.Colors.selectedText : KalirovaTheme.Colors.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var icon: String {
        switch type {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "takeoutbag.and.cup.and.straw.fill"
        case .custom: "fork.knife.circle.fill"
        }
    }
}

private struct NutritionReviewCard: View {
    var name: String
    var serving: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var confidence: EstimateConfidence

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Food item" : name)
                        .font(.kalirovaMetric)
                        .foregroundStyle(KalirovaTheme.Colors.textPrimary)
                    if !serving.isEmpty {
                        Text(serving)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    }
                }

                Text(calories.kcalText)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    SummaryPillMini(title: "Protein", value: "\(protein.formatted(.number.precision(.fractionLength(0)))) g")
                    SummaryPillMini(title: "Carbs", value: "\(carbs.formatted(.number.precision(.fractionLength(0)))) g")
                    SummaryPillMini(title: "Fat", value: "\(fat.formatted(.number.precision(.fractionLength(0)))) g")
                    SummaryPillMini(title: "Confidence", value: confidence.rawValue.capitalized)
                }
            }
        }
    }
}

private struct OpenAIPrivacyConfirmationSheet: View {
    var preview: OpenAIRequestPreview?
    var mealInformationPayload: String
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("What Will Be Sent") {
                    Text("Only the meal information below will be sent to OpenAI for this request. HealthKit data, profile data, saved meals, and API keys are not included in the prompt.")
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)

                    ScrollView(.horizontal) {
                        Text(mealInformationPayload)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                if let preview {
                    Section("Request") {
                        LabeledContent("Endpoint", value: preview.endpoint)
                        LabeledContent("Model", value: preview.model)
                        Text(preview.purpose)
                            .font(.footnote)
                            .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                    }
                }

                Section("Before You Send") {
                    Text("Restaurant nutrition estimates may vary by preparation and portion size. The estimate will not be saved automatically.")
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }
            }
            .navigationTitle("ChatGPT Privacy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send", action: onConfirm)
                }
            }
        }
    }
}

private struct OpenAIRestaurantEstimateSummary: View {
    var analysis: OpenAIMealAnalysis

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Estimate")
                    .font(.headline)
                    .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                Text(analysis.totalCalories.kcalText)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    SummaryPillMini(title: "Protein", value: "\(analysis.totalProteinGrams.formatted(.number.precision(.fractionLength(0)))) g")
                    SummaryPillMini(title: "Carbs", value: "\(analysis.totalCarbohydrateGrams.formatted(.number.precision(.fractionLength(0)))) g")
                    SummaryPillMini(title: "Fat", value: "\(analysis.totalFatGrams.formatted(.number.precision(.fractionLength(0)))) g")
                    SummaryPillMini(title: "Confidence", value: analysis.confidence.capitalized)
                }
                if !analysis.assumptions.isEmpty {
                    Text("Assumptions: \(analysis.assumptions.joined(separator: "; "))")
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }
                if !analysis.sourceNotes.isEmpty {
                    Text("Source notes: \(analysis.sourceNotes.joined(separator: "; "))")
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }
                if !analysis.disclaimer.isEmpty {
                    Text(analysis.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(KalirovaTheme.Colors.textSecondary)
                }
            }
        }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(KalirovaTheme.Colors.surfaceSubtle.opacity(KalirovaTheme.Opacity.elevatedFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension String {
    var normalizedMealKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

#Preview {
    MealLogView()
}
