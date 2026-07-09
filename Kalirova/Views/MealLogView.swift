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
                    Section(group.date.formatted(date: .complete, time: .omitted)) {
                        ForEach(group.meals) { meal in
                            MealContainerRow(meal: meal, showsDate: false)
                        }
                        .onDelete { offsets in
                            deleteMeals(at: offsets, in: group)
                        }
                    }
                }
            }
            .overlay {
                if meals.isEmpty {
                    ContentUnavailableView("No meals logged", systemImage: "fork.knife")
                }
            }
            .navigationTitle("Meal Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMeal = true
                    } label: {
                        Label("Add Food", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(settings: settings.first)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.displayTitle)
                        .font(.headline)
                    if showsDate {
                        Text(meal.loggedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(meal.totalCalories.kcalText)
                    .font(.subheadline.weight(.semibold))
            }

            if meal.items.isEmpty {
                Text("No food items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(meal.items) { item in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                if !item.servingDescription.isEmpty {
                                    Text(item.servingDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(item.calories.kcalText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Label("\(meal.totalProtein.formatted(.number.precision(.fractionLength(0))))g protein", systemImage: "p.circle")
                Label("\(meal.items.count) item\(meal.items.count == 1 ? "" : "s")", systemImage: "list.bullet")
                Label(meal.source.displayName, systemImage: "tag")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var existingMeals: [MealEntry]

    var settings: AppSettings?

    @State private var loggedAt = Date()
    @State private var mealType: MealType = .breakfast
    @State private var customMealTypeName = ""
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

    private let nutritionService = NutritionService()
    private let openAIService = OpenAIService()

    private var canSave: Bool {
        let hasFoodName = !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCustomMealName = mealType != .custom || !customMealTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasFoodName && hasCustomMealName
    }

    private var canEstimateRestaurantMeal: Bool {
        !restaurantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !servingDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    DatePicker("Date", selection: $loggedAt, displayedComponents: .date)

                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases) { mealType in
                            Text(mealType.displayName).tag(mealType)
                        }
                    }
                    .pickerStyle(.menu)

                    if mealType == .custom {
                        TextField("Custom meal type", text: $customMealTypeName)
                    }
                }

                Section("Food") {
                    TextField("Restaurant name", text: $restaurantName)
                    TextField("Food item", text: $foodName)
                    TextField("Portion or measurement", text: $servingDescription)
                    TextEditor(text: $mealText)
                        .frame(minHeight: 88)
                        .overlay(alignment: .topLeading) {
                            if mealText.isEmpty {
                                Text("Notes or modifications")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        }
                }

                Section("Nutrition") {
                    nutritionField("Calories", value: $manualCalories, unit: "kcal")
                    nutritionField("Protein", value: $manualProtein, unit: "g")
                    nutritionField("Carbs", value: $manualCarbs, unit: "g")
                    nutritionField("Fat", value: $manualFat, unit: "g")
                    nutritionField("Fiber", value: $manualFiber, unit: "g")
                    nutritionField("Sugar", value: $manualSugar, unit: "g")
                    nutritionField("Sodium", value: $manualSodium, unit: "mg")
                }

                Section("Local Estimate") {
                    Button {
                        applyLocalEstimate()
                    } label: {
                        Label("Estimate Locally", systemImage: "wand.and.stars")
                    }
                    .disabled(localEstimateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let localEstimate {
                        NutritionEstimateSummary(estimate: localEstimate)
                    }
                }

                Section("ChatGPT Restaurant Estimate") {
                    Text("Restaurant nutrition estimates may vary by preparation and portion size. Review and edit the estimate before saving.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        prepareAIPrivacyConfirmation()
                    } label: {
                        if isEstimatingWithAI {
                            Label("Estimating", systemImage: "hourglass")
                        } else {
                            Label("Estimate With ChatGPT", systemImage: "sparkles")
                        }
                    }
                    .disabled(!canEstimateRestaurantMeal || isEstimatingWithAI)

                    if let aiEstimate {
                        OpenAIRestaurantEstimateSummary(analysis: aiEstimate)

                        Button {
                            applyAIEstimate(aiEstimate)
                        } label: {
                            Label("Apply Estimate to Form", systemImage: "square.and.pencil")
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Food")
            .sheet(isPresented: $showingAIPrivacyConfirmation) {
                OpenAIPrivacyConfirmationSheet(
                    preview: aiPayloadPreview,
                    mealInformationPayload: aiPrivacyPayload,
                    onCancel: {
                        showingAIPrivacyConfirmation = false
                    },
                    onConfirm: {
                        showingAIPrivacyConfirmation = false
                        Task { await estimateRestaurantMeal() }
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFoodItem()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var localEstimateText: String {
        [restaurantName, foodName, servingDescription, mealText]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var mealDisplayTitle: String {
        if mealType == .custom {
            return customMealTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return mealType.displayName
    }

    private func nutritionField(_ label: String, value: Binding<Double>, unit: String) -> some View {
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

    @MainActor
    private func estimateRestaurantMeal() async {
        isEstimatingWithAI = true
        defer { isEstimatingWithAI = false }

        do {
            let apiKey = try KeychainService.shared.loadOpenAIAPIKey()
            aiEstimate = try await openAIService.estimateRestaurantMeal(
                request: restaurantEstimateRequest,
                model: settings?.openAIModel ?? "gpt-5.5",
                apiKey: apiKey
            )
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

            guard mealType == .custom else {
                return true
            }

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
        if !trimmedRestaurant.isEmpty {
            lines.append("Restaurant: \(trimmedRestaurant)")
        }

        let trimmedNotes = mealText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            lines.append("Notes: \(trimmedNotes)")
        }

        if selectedSource == .openAI, let aiEstimate {
            if !aiEstimate.assumptions.isEmpty {
                lines.append("ChatGPT assumptions: \(aiEstimate.assumptions.joined(separator: "; "))")
            }

            if !aiEstimate.sourceNotes.isEmpty {
                lines.append("ChatGPT source notes: \(aiEstimate.sourceNotes.joined(separator: "; "))")
            }

            if !aiEstimate.disclaimer.isEmpty {
                lines.append("ChatGPT disclaimer: \(aiEstimate.disclaimer)")
            }
        }

        return lines.joined(separator: "\n")
    }
}

private struct NutritionEstimateSummary: View {
    var estimate: MealNutritionEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SummaryRow(label: "Calories", value: estimate.totals.calories.kcalText)
            SummaryRow(label: "Protein", value: "\(estimate.totals.proteinGrams.formatted(.number.precision(.fractionLength(1)))) g")
            SummaryRow(label: "Carbs", value: "\(estimate.totals.carbohydrateGrams.formatted(.number.precision(.fractionLength(1)))) g")
            SummaryRow(label: "Fat", value: "\(estimate.totals.fatGrams.formatted(.number.precision(.fractionLength(1)))) g")
            Text("Confidence: \(estimate.confidence.rawValue.capitalized)")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)

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
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Before You Send") {
                    Text("Restaurant nutrition estimates may vary by preparation and portion size. The estimate will not be saved automatically.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            SummaryRow(label: "Calories", value: analysis.totalCalories.kcalText)
            SummaryRow(label: "Protein", value: "\(analysis.totalProteinGrams.formatted(.number.precision(.fractionLength(1)))) g")
            SummaryRow(label: "Carbs", value: "\(analysis.totalCarbohydrateGrams.formatted(.number.precision(.fractionLength(1)))) g")
            SummaryRow(label: "Fat", value: "\(analysis.totalFatGrams.formatted(.number.precision(.fractionLength(1)))) g")
            Text("Confidence: \(analysis.confidence.capitalized)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !analysis.assumptions.isEmpty {
                Text("Assumptions: \(analysis.assumptions.joined(separator: "; "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !analysis.sourceNotes.isEmpty {
                Text("Source notes: \(analysis.sourceNotes.joined(separator: "; "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !analysis.disclaimer.isEmpty {
                Text(analysis.disclaimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
