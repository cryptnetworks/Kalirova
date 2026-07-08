import Combine
import Foundation

struct DashboardTotals {
    var caloriesIn: Double
    var deviceCaloriesOut: Double
    var appCaloriesOut: Double
    var netCalories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var workoutMinutes: Double
    var steps: Int
    var waterLiters: Double
    var sleepHours: Double
    var weightKg: Double?
}

@MainActor
final class DashboardViewModel: ObservableObject {
    func totals(
        meals: [MealEntry],
        workouts: [WorkoutEntry],
        metrics: [HealthMetricEntry],
        period: DashboardPeriod,
        referenceDate: Date = .now
    ) -> DashboardTotals {
        let calendar = Calendar.current
        let filteredMeals = meals.filter { period.contains($0.loggedAt, referenceDate: referenceDate, calendar: calendar) }
        let filteredWorkouts = workouts.filter { period.contains($0.startedAt, referenceDate: referenceDate, calendar: calendar) }
        let filteredMetrics = metrics.filter { period.contains($0.loggedAt, referenceDate: referenceDate, calendar: calendar) }

        let caloriesIn = filteredMeals.reduce(0) { $0 + $1.totalCalories }
        let deviceOut = filteredWorkouts.reduce(0) { $0 + ($1.deviceReportedCalories ?? 0) }
        let appOut = filteredWorkouts.reduce(0) { $0 + ($1.appEstimatedCalories ?? 0) }

        return DashboardTotals(
            caloriesIn: caloriesIn,
            deviceCaloriesOut: deviceOut,
            appCaloriesOut: appOut,
            netCalories: caloriesIn - appOut,
            protein: filteredMeals.reduce(0) { $0 + $1.totalProtein },
            carbohydrates: filteredMeals.reduce(0) { $0 + $1.totalCarbohydrates },
            fat: filteredMeals.reduce(0) { $0 + $1.totalFat },
            workoutMinutes: filteredWorkouts.reduce(0) { $0 + $1.durationMinutes },
            steps: Int(filteredMetrics.filter { $0.type == .steps }.reduce(0) { $0 + $1.value }),
            waterLiters: filteredMetrics.filter { $0.type == .water }.reduce(0) { $0 + $1.value },
            sleepHours: filteredMetrics.filter { $0.type == .sleep }.reduce(0) { $0 + $1.value },
            weightKg: filteredMetrics
                .filter { $0.type == .bodyMass }
                .sorted { $0.loggedAt > $1.loggedAt }
                .first?
                .value
        )
    }
}

enum DashboardPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    func contains(_ date: Date, referenceDate: Date, calendar: Calendar) -> Bool {
        switch self {
        case .day:
            return calendar.isDate(date, inSameDayAs: referenceDate)
        case .week:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
        case .year:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .year)
        }
    }
}

@MainActor
final class ExerciseViewModel: ObservableObject {
    private let estimator = CalorieBurnEstimator()

    func estimate(
        kind: WorkoutKind,
        durationMinutes: Double,
        bodyMassKg: Double?,
        averageHeartRate: Int?,
        distanceMeters: Double?,
        perceivedEffort: PerceivedEffort?,
        profile: UserProfile?
    ) -> CalorieEstimate {
        estimator.estimate(
            workout: WorkoutInput(
                kind: kind,
                durationMinutes: durationMinutes,
                bodyMassKg: bodyMassKg,
                averageHeartRate: averageHeartRate,
                distanceMeters: distanceMeters,
                perceivedEffort: perceivedEffort
            ),
            profile: profile?.snapshot ?? UserProfileSnapshot(bodyMassKg: bodyMassKg)
        )
    }
}

enum PreviewData {
    static var meals: [MealEntry] {
        [
            MealEntry(
                title: "Breakfast",
                source: .localParser,
                confidence: .medium,
                items: [
                    FoodItem(name: "Eggs", servingDescription: "2 servings", calories: 144, proteinGrams: 12.6, carbohydrateGrams: 0.8, fatGrams: 9.6),
                    FoodItem(name: "Toast", servingDescription: "1 serving", calories: 80, proteinGrams: 3, carbohydrateGrams: 15, fatGrams: 1)
                ]
            )
        ]
    }

    static var workouts: [WorkoutEntry] {
        [
            WorkoutEntry(
                title: "Morning Run",
                durationMinutes: 32,
                kind: .running,
                sourceName: "Apple Watch",
                deviceReportedCalories: 310,
                appEstimatedCalories: 336,
                estimateConfidence: .high,
                averageHeartRate: 158,
                bodyMassKg: 82,
                distanceMeters: 5_200
            )
        ]
    }
}
