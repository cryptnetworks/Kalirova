import Foundation

public struct NutrientTotals: Codable, Equatable, Sendable {
    public var calories: Double
    public var proteinGrams: Double
    public var carbohydrateGrams: Double
    public var fatGrams: Double
    public var fiberGrams: Double
    public var sugarGrams: Double
    public var sodiumMilligrams: Double

    public init(
        calories: Double = 0,
        proteinGrams: Double = 0,
        carbohydrateGrams: Double = 0,
        fatGrams: Double = 0,
        fiberGrams: Double = 0,
        sugarGrams: Double = 0,
        sodiumMilligrams: Double = 0
    ) {
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.sugarGrams = sugarGrams
        self.sodiumMilligrams = sodiumMilligrams
    }

    public static func + (lhs: NutrientTotals, rhs: NutrientTotals) -> NutrientTotals {
        NutrientTotals(
            calories: lhs.calories + rhs.calories,
            proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
            carbohydrateGrams: lhs.carbohydrateGrams + rhs.carbohydrateGrams,
            fatGrams: lhs.fatGrams + rhs.fatGrams,
            fiberGrams: lhs.fiberGrams + rhs.fiberGrams,
            sugarGrams: lhs.sugarGrams + rhs.sugarGrams,
            sodiumMilligrams: lhs.sodiumMilligrams + rhs.sodiumMilligrams
        )
    }
}

public struct ParsedFoodItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var quantityDescription: String
    public var nutrients: NutrientTotals
    public var assumptions: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        quantityDescription: String,
        nutrients: NutrientTotals,
        assumptions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.quantityDescription = quantityDescription
        self.nutrients = nutrients
        self.assumptions = assumptions
    }
}

public struct MealNutritionEstimate: Codable, Equatable, Sendable {
    public var originalText: String
    public var items: [ParsedFoodItem]
    public var totals: NutrientTotals
    public var confidence: EstimateConfidence
    public var assumptions: [String]

    public init(
        originalText: String,
        items: [ParsedFoodItem],
        totals: NutrientTotals,
        confidence: EstimateConfidence,
        assumptions: [String]
    ) {
        self.originalText = originalText
        self.items = items
        self.totals = totals
        self.confidence = confidence
        self.assumptions = assumptions
    }
}

public final class NutritionService: Sendable {
    public init() {}

    public func parseLocalMealDescription(_ text: String) -> MealNutritionEstimate {
        let normalized = text.lowercased()
        let matchedItems = knownFoods.compactMap { food -> ParsedFoodItem? in
            guard normalized.contains(food.key) else { return nil }
            let quantity = quantityMultiplier(near: food.key, in: normalized)
            return ParsedFoodItem(
                name: food.displayName,
                quantityDescription: quantity.description,
                nutrients: food.nutrients.scaled(by: quantity.value),
                assumptions: ["Local fallback estimate based on common serving size."]
            )
        }

        if matchedItems.isEmpty {
            return MealNutritionEstimate(
                originalText: text,
                items: [],
                totals: NutrientTotals(),
                confidence: .low,
                assumptions: ["No known local foods matched. Use manual entry or optional AI parsing."]
            )
        }

        let totals = matchedItems.reduce(NutrientTotals()) { $0 + $1.nutrients }.rounded()
        let confidence: EstimateConfidence = matchedItems.count >= 2 ? .medium : .low

        return MealNutritionEstimate(
            originalText: text,
            items: matchedItems,
            totals: totals,
            confidence: confidence,
            assumptions: matchedItems.flatMap(\.assumptions)
        )
    }

    private func quantityMultiplier(near key: String, in text: String) -> (value: Double, description: String) {
        let tokens = text
            .replacingOccurrences(of: ",", with: " ")
            .split(separator: " ")
            .map(String.init)

        guard let index = tokens.firstIndex(where: { $0.contains(key) || key.contains($0) }) else {
            return (1, "1 serving")
        }

        guard index > tokens.startIndex else {
            return (1, "1 serving")
        }

        let previousIndex = tokens.index(before: index)
        let previous = tokens[previousIndex]
        if let number = Double(previous) {
            return (max(0.25, number), "\(number.cleanDescription) servings")
        }

        return (1, "1 serving")
    }

    private let knownFoods: [KnownFood] = [
        KnownFood(
            key: "egg",
            displayName: "Egg",
            nutrients: NutrientTotals(calories: 72, proteinGrams: 6.3, carbohydrateGrams: 0.4, fatGrams: 4.8, sodiumMilligrams: 71)
        ),
        KnownFood(
            key: "toast",
            displayName: "Toast",
            nutrients: NutrientTotals(calories: 80, proteinGrams: 3, carbohydrateGrams: 15, fatGrams: 1, fiberGrams: 1.2, sugarGrams: 1.4, sodiumMilligrams: 150)
        ),
        KnownFood(
            key: "butter",
            displayName: "Butter",
            nutrients: NutrientTotals(calories: 102, fatGrams: 11.5, sodiumMilligrams: 91)
        ),
        KnownFood(
            key: "coffee",
            displayName: "Coffee",
            nutrients: NutrientTotals(calories: 2)
        ),
        KnownFood(
            key: "milk",
            displayName: "Milk",
            nutrients: NutrientTotals(calories: 61, proteinGrams: 3.2, carbohydrateGrams: 4.8, fatGrams: 3.3, sugarGrams: 5.1, sodiumMilligrams: 43)
        ),
        KnownFood(
            key: "chicken",
            displayName: "Chicken Breast",
            nutrients: NutrientTotals(calories: 165, proteinGrams: 31, fatGrams: 3.6, sodiumMilligrams: 74)
        ),
        KnownFood(
            key: "rice",
            displayName: "Rice",
            nutrients: NutrientTotals(calories: 206, proteinGrams: 4.3, carbohydrateGrams: 45, fatGrams: 0.4, fiberGrams: 0.6)
        ),
        KnownFood(
            key: "banana",
            displayName: "Banana",
            nutrients: NutrientTotals(calories: 105, proteinGrams: 1.3, carbohydrateGrams: 27, fatGrams: 0.4, fiberGrams: 3.1, sugarGrams: 14.4, sodiumMilligrams: 1)
        )
    ]
}

private struct KnownFood: Sendable {
    var key: String
    var displayName: String
    var nutrients: NutrientTotals
}

private extension NutrientTotals {
    func scaled(by multiplier: Double) -> NutrientTotals {
        NutrientTotals(
            calories: calories * multiplier,
            proteinGrams: proteinGrams * multiplier,
            carbohydrateGrams: carbohydrateGrams * multiplier,
            fatGrams: fatGrams * multiplier,
            fiberGrams: fiberGrams * multiplier,
            sugarGrams: sugarGrams * multiplier,
            sodiumMilligrams: sodiumMilligrams * multiplier
        ).rounded()
    }

    func rounded() -> NutrientTotals {
        NutrientTotals(
            calories: calories.rounded(toPlaces: 1),
            proteinGrams: proteinGrams.rounded(toPlaces: 1),
            carbohydrateGrams: carbohydrateGrams.rounded(toPlaces: 1),
            fatGrams: fatGrams.rounded(toPlaces: 1),
            fiberGrams: fiberGrams.rounded(toPlaces: 1),
            sugarGrams: sugarGrams.rounded(toPlaces: 1),
            sodiumMilligrams: sodiumMilligrams.rounded(toPlaces: 0)
        )
    }
}

private extension Double {
    var cleanDescription: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(self)
    }

    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}
