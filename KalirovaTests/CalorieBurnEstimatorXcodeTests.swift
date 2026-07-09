import XCTest
@testable import Kalirova

final class CalorieBurnEstimatorXcodeTests: XCTestCase {
    func testAppEstimateKeepsAlgorithmMetadata() {
        let estimate = CalorieBurnEstimator().estimate(
            workout: WorkoutInput(kind: .cycling, durationMinutes: 45, averageHeartRate: 145),
            profile: UserProfileSnapshot(ageYears: 36, bodyMassKg: 82, restingHeartRate: 58)
        )

        XCTAssertEqual(estimate.confidence, .high)
        XCTAssertEqual(estimate.algorithmVersion, CalorieBurnEstimator.algorithmVersion)
        XCTAssertGreaterThan(estimate.calories, 300)
    }
}

final class DailySnapshotBuilderXcodeTests: XCTestCase {
    func testSnapshotsAggregateRecordsOncePerDay() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let meal = MealEntry(
            title: "Lunch",
            loggedAt: day,
            mealType: .lunch,
            items: [
                FoodItem(
                    name: "Bowl",
                    servingDescription: "1 bowl",
                    calories: 620,
                    proteinGrams: 42,
                    carbohydrateGrams: 58,
                    fatGrams: 22
                )
            ]
        )
        let workout = WorkoutEntry(
            title: "Run",
            startedAt: day.addingTimeInterval(3_600),
            durationMinutes: 35,
            kind: .running,
            appEstimatedCalories: 410
        )
        let metrics = [
            HealthMetricEntry(type: .steps, value: 4_200, unit: "steps", loggedAt: day.addingTimeInterval(500)),
            HealthMetricEntry(type: .water, value: 1.25, unit: "L", loggedAt: day.addingTimeInterval(800)),
            HealthMetricEntry(type: .sleep, value: 7.5, unit: "hr", loggedAt: day.addingTimeInterval(1_000))
        ]

        let snapshots = DailySnapshotBuilder.snapshots(
            meals: [meal],
            workouts: [workout],
            metrics: metrics,
            period: .day,
            referenceDate: day
        )

        XCTAssertEqual(snapshots.count, 1)
        let snapshot = snapshots[0]
        XCTAssertEqual(snapshot.nutrition.calories, 620)
        XCTAssertEqual(snapshot.nutrition.proteinGrams, 42)
        XCTAssertEqual(snapshot.nutrition.carbohydrateGrams, 58)
        XCTAssertEqual(snapshot.nutrition.fatGrams, 22)
        XCTAssertEqual(snapshot.activeEnergyBurned, 410)
        XCTAssertEqual(snapshot.workoutMinutes, 35)
        XCTAssertEqual(snapshot.steps, 4_200)
        XCTAssertEqual(snapshot.waterLiters, 1.25)
        XCTAssertEqual(snapshot.sleepHours, 7.5)
    }

    func testSnapshotsKeepLatestBodyMassForTheDay() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let metrics = [
            HealthMetricEntry(type: .bodyMass, value: 82.2, unit: "kg", loggedAt: day.addingTimeInterval(100)),
            HealthMetricEntry(type: .bodyMass, value: 81.8, unit: "kg", loggedAt: day.addingTimeInterval(200))
        ]

        let snapshots = DailySnapshotBuilder.snapshots(
            meals: [],
            workouts: [],
            metrics: metrics,
            period: .day,
            referenceDate: day
        )

        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].bodyMassKg, 81.8)
    }
}
