import XCTest
@testable import KalirovaCore

final class HealthKitMappingTests: XCTestCase {
    func testWorkoutMappingPreservesDeviceReportedCaloriesSeparately() {
        let start = Date(timeIntervalSince1970: 1_800)
        let end = Date(timeIntervalSince1970: 3_600)
        let sample = HealthKitWorkoutSampleDTO(
            healthKitActivityType: "running",
            startedAt: start,
            endedAt: end,
            durationMinutes: 30,
            totalEnergyKilocalories: 250,
            distanceMeters: 5_000,
            averageHeartRate: 155,
            sourceName: "Apple Watch"
        )

        let result = HealthKitMapping.mapWorkout(sample)

        XCTAssertEqual(result.input.kind, .running)
        XCTAssertEqual(result.deviceReportedCalories, 250)
        XCTAssertEqual(result.input.averageHeartRate, 155)
        XCTAssertEqual(result.sourceName, "Apple Watch")
    }

    func testActivityTypeMappingHandlesCommonNames() {
        XCTAssertEqual(HealthKitMapping.mapActivityType("traditionalStrengthTraining"), .strengthTraining)
        XCTAssertEqual(HealthKitMapping.mapActivityType("outdoor_cycle"), .cycling)
        XCTAssertEqual(HealthKitMapping.mapActivityType("mind and body"), .other)
    }
}

