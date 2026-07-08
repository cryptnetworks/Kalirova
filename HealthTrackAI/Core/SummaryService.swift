import Foundation

public struct DailyHealthSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: Date { date }
    public var date: Date
    public var nutrition: NutrientTotals
    public var activeEnergyBurned: Double
    public var workoutMinutes: Double
    public var steps: Int
    public var waterLiters: Double
    public var sleepHours: Double
    public var bodyMassKg: Double?

    public init(
        date: Date,
        nutrition: NutrientTotals = NutrientTotals(),
        activeEnergyBurned: Double = 0,
        workoutMinutes: Double = 0,
        steps: Int = 0,
        waterLiters: Double = 0,
        sleepHours: Double = 0,
        bodyMassKg: Double? = nil
    ) {
        self.date = date
        self.nutrition = nutrition
        self.activeEnergyBurned = activeEnergyBurned
        self.workoutMinutes = workoutMinutes
        self.steps = steps
        self.waterLiters = waterLiters
        self.sleepHours = sleepHours
        self.bodyMassKg = bodyMassKg
    }
}

public struct GoalSnapshot: Codable, Equatable, Sendable {
    public var calorieTarget: Double?
    public var proteinTargetGrams: Double?
    public var stepTarget: Int?
    public var waterTargetLiters: Double?
    public var sleepTargetHours: Double?

    public init(
        calorieTarget: Double? = nil,
        proteinTargetGrams: Double? = nil,
        stepTarget: Int? = nil,
        waterTargetLiters: Double? = nil,
        sleepTargetHours: Double? = nil
    ) {
        self.calorieTarget = calorieTarget
        self.proteinTargetGrams = proteinTargetGrams
        self.stepTarget = stepTarget
        self.waterTargetLiters = waterTargetLiters
        self.sleepTargetHours = sleepTargetHours
    }
}

public struct WeeklySummary: Codable, Equatable, Sendable {
    public var averageCaloriesIn: Double
    public var averageCaloriesOut: Double
    public var averageProtein: Double
    public var averageSleep: Double
    public var averageSteps: Double
    public var workoutMinutes: Double
    public var weightTrendKg: Double?
    public var adherenceScore: Double
    public var narrative: String
    public var disclaimer: String

    public init(
        averageCaloriesIn: Double,
        averageCaloriesOut: Double,
        averageProtein: Double,
        averageSleep: Double,
        averageSteps: Double,
        workoutMinutes: Double,
        weightTrendKg: Double?,
        adherenceScore: Double,
        narrative: String,
        disclaimer: String
    ) {
        self.averageCaloriesIn = averageCaloriesIn
        self.averageCaloriesOut = averageCaloriesOut
        self.averageProtein = averageProtein
        self.averageSleep = averageSleep
        self.averageSteps = averageSteps
        self.workoutMinutes = workoutMinutes
        self.weightTrendKg = weightTrendKg
        self.adherenceScore = adherenceScore
        self.narrative = narrative
        self.disclaimer = disclaimer
    }
}

public final class SummaryService: Sendable {
    public static let wellnessDisclaimer = "This app is for wellness tracking only and is not medical advice."

    public init() {}

    public func weeklySummary(days: [DailyHealthSnapshot], goals: GoalSnapshot) -> WeeklySummary {
        guard !days.isEmpty else {
            return WeeklySummary(
                averageCaloriesIn: 0,
                averageCaloriesOut: 0,
                averageProtein: 0,
                averageSleep: 0,
                averageSteps: 0,
                workoutMinutes: 0,
                weightTrendKg: nil,
                adherenceScore: 0,
                narrative: "No local data is available for this week yet.",
                disclaimer: Self.wellnessDisclaimer
            )
        }

        let count = Double(days.count)
        let averageCaloriesIn = days.map(\.nutrition.calories).sum / count
        let averageCaloriesOut = days.map(\.activeEnergyBurned).sum / count
        let averageProtein = days.map(\.nutrition.proteinGrams).sum / count
        let averageSleep = days.map(\.sleepHours).sum / count
        let averageSteps = Double(days.map(\.steps).sum) / count
        let workoutMinutes = days.map(\.workoutMinutes).sum
        let weightTrendKg = weightTrend(from: days)
        let adherenceScore = adherence(days: days, goals: goals)

        let caloriePhrase = averageCaloriesIn > 0
            ? "Average intake was \(Int(averageCaloriesIn.rounded())) calories per day."
            : "Calorie intake was not logged consistently."
        let proteinPhrase = goals.proteinTargetGrams.map {
            averageProtein >= $0
                ? "Protein target was met on average."
                : "Protein averaged \(Int(averageProtein.rounded()))g against a \($0.cleanDescription)g target."
        } ?? "No protein target is active."
        let movementPhrase = "You logged \(Int(workoutMinutes.rounded())) workout minutes and averaged \(Int(averageSteps.rounded())) steps."
        let sleepPhrase = averageSleep > 0 ? "Sleep averaged \(averageSleep.rounded(toPlaces: 1)) hours." : "Sleep was not logged."

        return WeeklySummary(
            averageCaloriesIn: averageCaloriesIn.rounded(toPlaces: 1),
            averageCaloriesOut: averageCaloriesOut.rounded(toPlaces: 1),
            averageProtein: averageProtein.rounded(toPlaces: 1),
            averageSleep: averageSleep.rounded(toPlaces: 1),
            averageSteps: averageSteps.rounded(toPlaces: 0),
            workoutMinutes: workoutMinutes.rounded(toPlaces: 0),
            weightTrendKg: weightTrendKg?.rounded(toPlaces: 2),
            adherenceScore: adherenceScore.rounded(toPlaces: 2),
            narrative: [caloriePhrase, proteinPhrase, movementPhrase, sleepPhrase].joined(separator: " "),
            disclaimer: Self.wellnessDisclaimer
        )
    }

    private func weightTrend(from days: [DailyHealthSnapshot]) -> Double? {
        let samples = days
            .compactMap { day -> (Date, Double)? in
                guard let bodyMassKg = day.bodyMassKg else { return nil }
                return (day.date, bodyMassKg)
            }
            .sorted { $0.0 < $1.0 }

        guard let first = samples.first?.1, let last = samples.last?.1, samples.count >= 2 else {
            return nil
        }

        return last - first
    }

    private func adherence(days: [DailyHealthSnapshot], goals: GoalSnapshot) -> Double {
        var scores: [Double] = []

        if let calorieTarget = goals.calorieTarget, calorieTarget > 0 {
            scores += days.map { min($0.nutrition.calories / calorieTarget, 1) }
        }

        if let proteinTargetGrams = goals.proteinTargetGrams, proteinTargetGrams > 0 {
            scores += days.map { min($0.nutrition.proteinGrams / proteinTargetGrams, 1) }
        }

        if let stepTarget = goals.stepTarget, stepTarget > 0 {
            scores += days.map { min(Double($0.steps) / Double(stepTarget), 1) }
        }

        if let waterTargetLiters = goals.waterTargetLiters, waterTargetLiters > 0 {
            scores += days.map { min($0.waterLiters / waterTargetLiters, 1) }
        }

        if let sleepTargetHours = goals.sleepTargetHours, sleepTargetHours > 0 {
            scores += days.map { min($0.sleepHours / sleepTargetHours, 1) }
        }

        guard !scores.isEmpty else { return 0 }
        return scores.sum / Double(scores.count)
    }
}

private extension Array where Element == Double {
    var sum: Double {
        reduce(0, +)
    }
}

private extension Array where Element == Int {
    var sum: Int {
        reduce(0, +)
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

