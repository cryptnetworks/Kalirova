import SwiftData
import SwiftUI

struct MealLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealEntry.loggedAt, order: .reverse) private var meals: [MealEntry]
    @Query private var settings: [AppSettings]
    @State private var showingAddMeal = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(meals) { meal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(meal.title)
                                .font(.headline)
                            Spacer()
                            Text(meal.totalCalories.kcalText)
                                .fontWeight(.semibold)
                        }
                        Text(meal.loggedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Label("\(meal.totalProtein.formatted(.number.precision(.fractionLength(0))))g protein", systemImage: "p.circle")
                            Label(meal.source.displayName, systemImage: "tag")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteMeals)
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
                        Label("Add Meal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(settings: settings.first)
            }
        }
    }

    private func deleteMeals(at offsets: IndexSet) {
        offsets.map { meals[$0] }.forEach(modelContext.delete)
        try? modelContext.save()
    }
}

private struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var settings: AppSettings?

    @State private var title = "Meal"
    @State private var mealText = ""
    @State private var manualCalories = 0.0
    @State private var manualProtein = 0.0
    @State private var manualCarbs = 0.0
    @State private var manualFat = 0.0
    @State private var localEstimate: MealNutritionEstimate?
    @State private var aiPayloadPreview: OpenAIRequestPreview?
    @State private var errorMessage: String?

    private let nutritionService = NutritionService()
    private let openAIService = OpenAIService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Title", text: $title)
                    TextEditor(text: $mealText)
                        .frame(minHeight: 96)
                }

                Section("Manual Nutrition") {
                    nutritionField("Calories", value: $manualCalories, unit: "kcal")
                    nutritionField("Protein", value: $manualProtein, unit: "g")
                    nutritionField("Carbs", value: $manualCarbs, unit: "g")
                    nutritionField("Fat", value: $manualFat, unit: "g")
                }

                Section("Local Estimate") {
                    Button {
                        applyLocalEstimate()
                    } label: {
                        Label("Estimate Locally", systemImage: "wand.and.stars")
                    }

                    if let localEstimate {
                        NutritionEstimateSummary(estimate: localEstimate)
                    }
                }

                Section("ChatGPT Preview") {
                    Button {
                        createAIPreview()
                    } label: {
                        Label("Preview Payload", systemImage: "doc.text.magnifyingglass")
                    }
                    .disabled(mealText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let aiPayloadPreview {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(aiPayloadPreview.purpose)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal) {
                                Text(aiPayloadPreview.payload)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
        let estimate = nutritionService.parseLocalMealDescription(mealText)
        localEstimate = estimate
        manualCalories = estimate.totals.calories
        manualProtein = estimate.totals.proteinGrams
        manualCarbs = estimate.totals.carbohydrateGrams
        manualFat = estimate.totals.fatGrams
    }

    private func createAIPreview() {
        do {
            aiPayloadPreview = try openAIService.previewMealAnalysisPayload(
                mealText: mealText,
                model: settings?.openAIModel ?? "gpt-5.5"
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveMeal() {
        let item = FoodItem(
            name: title,
            servingDescription: "Manual entry",
            calories: manualCalories,
            proteinGrams: manualProtein,
            carbohydrateGrams: manualCarbs,
            fatGrams: manualFat
        )

        let meal = MealEntry(
            title: title,
            source: localEstimate == nil ? .manual : .localParser,
            confidence: localEstimate?.confidence ?? .medium,
            notes: mealText,
            items: [item]
        )

        modelContext.insert(meal)
        try? modelContext.save()
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

#Preview {
    MealLogView()
}

