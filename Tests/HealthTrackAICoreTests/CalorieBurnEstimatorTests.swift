import XCTest
@testable import HealthTrackAICore

final class CalorieBurnEstimatorTests: XCTestCase {
    func testMETEstimateUsesRequiredFormula() {
        let estimator = CalorieBurnEstimator()
        let estimate = estimator.estimate(
            workout: WorkoutInput(kind: .walking, durationMinutes: 30),
            profile: UserProfileSnapshot(bodyMassKg: 80)
        )

        XCTAssertEqual(estimate.calories, 147.0, accuracy: 0.1)
        XCTAssertEqual(estimate.confidence, .medium)
        XCTAssertEqual(estimate.algorithmVersion, CalorieBurnEstimator.algorithmVersion)
    }

    func testHeartRateEstimateIncreasesConfidenceAndCalories() {
        let estimator = CalorieBurnEstimator()
        let profile = UserProfileSnapshot(
            ageYears: 35,
            bodyMassKg: 80,
            restingHeartRate: 60,
            activityLevel: .moderatelyActive
        )

        let metEstimate = estimator.estimate(
            workout: WorkoutInput(kind: .running, durationMinutes: 30),
            profile: profile
        )

        let heartRateEstimate = estimator.estimate(
            workout: WorkoutInput(kind: .running, durationMinutes: 30, averageHeartRate: 165),
            profile: profile
        )

        XCTAssertEqual(heartRateEstimate.confidence, .high)
        XCTAssertGreaterThan(heartRateEstimate.calories, metEstimate.calories)
        XCTAssertEqual(heartRateEstimate.method, "heart-rate-zone-met")
    }

    func testMissingBodyMassIsLowConfidence() {
        let estimator = CalorieBurnEstimator()
        let estimate = estimator.estimate(
            workout: WorkoutInput(kind: .other, durationMinutes: 20),
            profile: UserProfileSnapshot()
        )

        XCTAssertEqual(estimate.confidence, .low)
        XCTAssertEqual(estimate.method, "generic-met")
    }
}

