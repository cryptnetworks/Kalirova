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

struct DashboardViewModel {
    func totals(
        meals: [MealEntry],
        workouts: [WorkoutEntry],
        metrics: [HealthMetricEntry],
        period: DashboardPeriod,
        referenceDate: Date = .now
    ) -> DashboardTotals {
        let calendar = Calendar.current
        var caloriesIn: Double = 0
        var protein: Double = 0
        var carbohydrates: Double = 0
        var fat: Double = 0
        var deviceOut: Double = 0
        var appOut: Double = 0
        var workoutMinutes: Double = 0
        var steps: Double = 0
        var waterLiters: Double = 0
        var sleepHours: Double = 0
        var weightKg: Double?
        var latestWeightDate: Date?

        for meal in meals where period.contains(meal.loggedAt, referenceDate: referenceDate, calendar: calendar) {
            caloriesIn += meal.totalCalories
            protein += meal.totalProtein
            carbohydrates += meal.totalCarbohydrates
            fat += meal.totalFat
        }

        for workout in workouts where period.contains(workout.startedAt, referenceDate: referenceDate, calendar: calendar) {
            deviceOut += workout.deviceReportedCalories ?? 0
            appOut += workout.appEstimatedCalories ?? 0
            workoutMinutes += workout.durationMinutes
        }

        for metric in metrics where period.contains(metric.loggedAt, referenceDate: referenceDate, calendar: calendar) {
            switch metric.type {
            case .steps:
                steps += metric.value
            case .water:
                waterLiters += metric.value
            case .sleep:
                sleepHours += metric.value
            case .bodyMass:
                if latestWeightDate == nil || metric.loggedAt > latestWeightDate ?? .distantPast {
                    weightKg = metric.value
                    latestWeightDate = metric.loggedAt
                }
            case .bodyFat, .heartRate, .mood, .note, .custom:
                break
            }
        }

        return DashboardTotals(
            caloriesIn: caloriesIn,
            deviceCaloriesOut: deviceOut,
            appCaloriesOut: appOut,
            netCalories: caloriesIn - appOut,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            workoutMinutes: workoutMinutes,
            steps: Int(steps),
            waterLiters: waterLiters,
            sleepHours: sleepHours,
            weightKg: weightKg
        )
    }
}

enum DashboardPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case threeMonths
    case year

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .day: "Today"
        case .week: "Week"
        case .month: "Month"
        case .threeMonths: "3 Months"
        case .year: "Year"
        }
    }

    func contains(_ date: Date, referenceDate: Date, calendar: Calendar) -> Bool {
        switch self {
        case .day:
            return calendar.isDate(date, inSameDayAs: referenceDate)
        case .week:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: referenceDate) ?? referenceDate
            return date >= startDate && date <= referenceDate
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
                mealType: .breakfast,
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
