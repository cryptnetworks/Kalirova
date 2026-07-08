import XCTest
@testable import HealthTrackAI

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

