import Foundation
import SwiftData

enum MealSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case localParser
    case openAI

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .manual: "Manual"
        case .localParser: "Local Parser"
        case .openAI: "ChatGPT"
        }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .custom: "Custom"
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .lunch: 1
        case .dinner: 2
        case .snack: 3
        case .custom: 4
        }
    }
}

enum MetricType: String, Codable, CaseIterable, Identifiable {
    case bodyMass
    case bodyFat
    case water
    case sleep
    case steps
    case heartRate
    case mood
    case note
    case custom

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .bodyMass: "Weight"
        case .bodyFat: "Body Fat"
        case .water: "Water"
        case .sleep: "Sleep"
        case .steps: "Steps"
        case .heartRate: "Heart Rate"
        case .mood: "Mood"
        case .note: "Note"
        case .custom: "Custom"
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case weight
    case calories
    case protein
    case steps
    case workouts
    case water
    case sleep

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .weight: "Weight"
        case .calories: "Calories"
        case .protein: "Protein"
        case .steps: "Steps"
        case .workouts: "Workouts"
        case .water: "Water"
        case .sleep: "Sleep"
        }
    }
}

enum GoalCadence: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

@Model
final class UserProfile {
    var id: UUID
    var ageYears: Int
    var sexRawValue: String
    var dateOfBirth: Date?
    var heightCentimeters: Double
    var bodyMassKg: Double
    var goalBodyMassKg: Double?
    var activityLevelRawValue: String
    var preferredUnitSystemRawValue: String
    var goalSummary: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        ageYears: Int,
        sex: BiologicalSex,
        dateOfBirth: Date? = nil,
        heightCentimeters: Double,
        bodyMassKg: Double,
        goalBodyMassKg: Double? = nil,
        activityLevel: ActivityLevel,
        preferredUnitSystem: UnitSystem = .metric,
        goalSummary: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ageYears = ageYears
        self.sexRawValue = sex.rawValue
        self.dateOfBirth = dateOfBirth
        self.heightCentimeters = heightCentimeters
        self.bodyMassKg = bodyMassKg
        self.goalBodyMassKg = goalBodyMassKg
        self.activityLevelRawValue = activityLevel.rawValue
        self.preferredUnitSystemRawValue = preferredUnitSystem.rawValue
        self.goalSummary = goalSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sex: BiologicalSex {
        BiologicalSex(rawValue: sexRawValue) ?? .notSpecified
    }

    var activityLevel: ActivityLevel {
        ActivityLevel(rawValue: activityLevelRawValue) ?? .moderatelyActive
    }

    var preferredUnitSystem: UnitSystem {
        UnitSystem(rawValue: preferredUnitSystemRawValue) ?? .metric
    }

    var snapshot: UserProfileSnapshot {
        UserProfileSnapshot(
            ageYears: ageYears,
            sex: sex,
            bodyMassKg: bodyMassKg,
            activityLevel: activityLevel
        )
    }
}

@Model
final class DailySummary {
    var id: UUID
    var date: Date
    var caloriesIn: Double
    var deviceReportedCaloriesOut: Double
    var appEstimatedCaloriesOut: Double
    var netCalories: Double
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var steps: Int
    var waterLiters: Double
    var sleepHours: Double
    var workoutMinutes: Double
    var adherenceScore: Double
    var generatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        caloriesIn: Double = 0,
        deviceReportedCaloriesOut: Double = 0,
        appEstimatedCaloriesOut: Double = 0,
        netCalories: Double = 0,
        proteinGrams: Double = 0,
        carbohydrateGrams: Double = 0,
        fatGrams: Double = 0,
        steps: Int = 0,
        waterLiters: Double = 0,
        sleepHours: Double = 0,
        workoutMinutes: Double = 0,
        adherenceScore: Double = 0,
        generatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.caloriesIn = caloriesIn
        self.deviceReportedCaloriesOut = deviceReportedCaloriesOut
        self.appEstimatedCaloriesOut = appEstimatedCaloriesOut
        self.netCalories = netCalories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.steps = steps
        self.waterLiters = waterLiters
        self.sleepHours = sleepHours
        self.workoutMinutes = workoutMinutes
        self.adherenceScore = adherenceScore
        self.generatedAt = generatedAt
    }
}

@Model
final class MealEntry {
    var id: UUID
    var title: String
    var loggedAt: Date
    var mealTypeRawValue: String
    var customMealTypeName: String
    var sourceRawValue: String
    var confidenceRawValue: String
    var notes: String
    @Relationship(deleteRule: .cascade) var items: [FoodItem]

    init(
        id: UUID = UUID(),
        title: String,
        loggedAt: Date = .now,
        mealType: MealType = .custom,
        customMealTypeName: String = "",
        source: MealSource = .manual,
        confidence: EstimateConfidence = .medium,
        notes: String = "",
        items: [FoodItem] = []
    ) {
        self.id = id
        self.title = title
        self.loggedAt = loggedAt
        self.mealTypeRawValue = mealType.rawValue
        self.customMealTypeName = customMealTypeName
        self.sourceRawValue = source.rawValue
        self.confidenceRawValue = confidence.rawValue
        self.notes = notes
        self.items = items
    }

    var mealType: MealType {
        MealType(rawValue: mealTypeRawValue) ?? .custom
    }

    var displayTitle: String {
        if mealType == .custom {
            let trimmedCustomName = customMealTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedCustomName.isEmpty {
                return trimmedCustomName
            }

            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedTitle.isEmpty ? mealType.displayName : trimmedTitle
        }

        return mealType.displayName
    }

    var source: MealSource {
        MealSource(rawValue: sourceRawValue) ?? .manual
    }

    var confidence: EstimateConfidence {
        EstimateConfidence(rawValue: confidenceRawValue) ?? .low
    }

    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        items.reduce(0) { $0 + $1.proteinGrams }
    }

    var totalCarbohydrates: Double {
        items.reduce(0) { $0 + $1.carbohydrateGrams }
    }

    var totalFat: Double {
        items.reduce(0) { $0 + $1.fatGrams }
    }
}

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var servingDescription: String
    var calories: Double
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var fiberGrams: Double
    var sugarGrams: Double
    var sodiumMilligrams: Double

    init(
        id: UUID = UUID(),
        name: String,
        servingDescription: String,
        calories: Double,
        proteinGrams: Double = 0,
        carbohydrateGrams: Double = 0,
        fatGrams: Double = 0,
        fiberGrams: Double = 0,
        sugarGrams: Double = 0,
        sodiumMilligrams: Double = 0
    ) {
        self.id = id
        self.name = name
        self.servingDescription = servingDescription
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.sugarGrams = sugarGrams
        self.sodiumMilligrams = sodiumMilligrams
    }
}

@Model
final class WorkoutEntry {
    var id: UUID
    var title: String
    var startedAt: Date
    var durationMinutes: Double
    var kindRawValue: String
    var sourceName: String
    var deviceReportedCalories: Double?
    var appEstimatedCalories: Double?
    var estimateConfidenceRawValue: String
    var algorithmVersion: String
    var averageHeartRate: Int?
    var bodyMassKg: Double?
    var distanceMeters: Double?
    var perceivedEffortRawValue: String?
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date = .now,
        durationMinutes: Double,
        kind: WorkoutKind,
        sourceName: String = "Manual",
        deviceReportedCalories: Double? = nil,
        appEstimatedCalories: Double? = nil,
        estimateConfidence: EstimateConfidence = .low,
        algorithmVersion: String = CalorieBurnEstimator.algorithmVersion,
        averageHeartRate: Int? = nil,
        bodyMassKg: Double? = nil,
        distanceMeters: Double? = nil,
        perceivedEffort: PerceivedEffort? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.kindRawValue = kind.rawValue
        self.sourceName = sourceName
        self.deviceReportedCalories = deviceReportedCalories
        self.appEstimatedCalories = appEstimatedCalories
        self.estimateConfidenceRawValue = estimateConfidence.rawValue
        self.algorithmVersion = algorithmVersion
        self.averageHeartRate = averageHeartRate
        self.bodyMassKg = bodyMassKg
        self.distanceMeters = distanceMeters
        self.perceivedEffortRawValue = perceivedEffort?.rawValue
        self.notes = notes
    }

    var kind: WorkoutKind {
        WorkoutKind(rawValue: kindRawValue) ?? .other
    }

    var estimateConfidence: EstimateConfidence {
        EstimateConfidence(rawValue: estimateConfidenceRawValue) ?? .low
    }

    var perceivedEffort: PerceivedEffort? {
        guard let perceivedEffortRawValue else { return nil }
        return PerceivedEffort(rawValue: perceivedEffortRawValue)
    }
}

@Model
final class HealthMetricEntry {
    var id: UUID
    var typeRawValue: String
    var customName: String
    var value: Double
    var unit: String
    var loggedAt: Date
    var note: String
    var sourceName: String

    init(
        id: UUID = UUID(),
        type: MetricType,
        customName: String = "",
        value: Double,
        unit: String,
        loggedAt: Date = .now,
        note: String = "",
        sourceName: String = "Manual"
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.customName = customName
        self.value = value
        self.unit = unit
        self.loggedAt = loggedAt
        self.note = note
        self.sourceName = sourceName
    }

    var type: MetricType {
        MetricType(rawValue: typeRawValue) ?? .custom
    }

    var displayName: String {
        customName.isEmpty ? type.displayName : customName
    }
}

@Model
final class Goal {
    var id: UUID
    var typeRawValue: String
    var targetValue: Double
    var unit: String
    var cadenceRawValue: String
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: GoalType,
        targetValue: Double,
        unit: String,
        cadence: GoalCadence,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.targetValue = targetValue
        self.unit = unit
        self.cadenceRawValue = cadence.rawValue
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var type: GoalType {
        GoalType(rawValue: typeRawValue) ?? .calories
    }

    var cadence: GoalCadence {
        GoalCadence(rawValue: cadenceRawValue) ?? .daily
    }
}

@Model
final class AISummary {
    var id: UUID
    var createdAt: Date
    var startDate: Date
    var endDate: Date
    var payloadPreview: String
    var responseText: String
    var model: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        startDate: Date,
        endDate: Date,
        payloadPreview: String,
        responseText: String,
        model: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.payloadPreview = payloadPreview
        self.responseText = responseText
        self.model = model
    }
}

@Model
final class AppSettings {
    var id: UUID
    var aiFeaturesEnabled: Bool
    var healthKitSyncEnabled: Bool
    var showDeviceCalories: Bool
    var showAppEstimatedCalories: Bool
    var openAIModel: String
    var unitSystemRawValue: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        aiFeaturesEnabled: Bool = false,
        healthKitSyncEnabled: Bool = false,
        showDeviceCalories: Bool = true,
        showAppEstimatedCalories: Bool = true,
        openAIModel: String = "gpt-5.5",
        unitSystem: UnitSystem = .metric,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.aiFeaturesEnabled = aiFeaturesEnabled
        self.healthKitSyncEnabled = healthKitSyncEnabled
        self.showDeviceCalories = showDeviceCalories
        self.showAppEstimatedCalories = showAppEstimatedCalories
        self.openAIModel = openAIModel
        self.unitSystemRawValue = unitSystem.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var unitSystem: UnitSystem {
        UnitSystem(rawValue: unitSystemRawValue) ?? .metric
    }
}
