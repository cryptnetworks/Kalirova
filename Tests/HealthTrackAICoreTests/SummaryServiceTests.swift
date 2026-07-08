import XCTest
@testable import HealthTrackAICore

final class SummaryServiceTests: XCTestCase {
    func testWeeklySummaryCalculatesAveragesAndDisclaimer() throws {
        let service = SummaryService()
        let baseDate = Date(timeIntervalSince1970: 0)
        let days = (0..<7).map { offset in
            DailyHealthSnapshot(
                date: baseDate.addingTimeInterval(Double(offset) * 86_400),
                nutrition: NutrientTotals(calories: 2_000, proteinGrams: 130),
                activeEnergyBurned: 600,
                workoutMinutes: 35,
                steps: 9_000,
                waterLiters: 2.5,
                sleepHours: 7.25,
                bodyMassKg: 82 - Double(offset) * 0.1
            )
        }

        let summary = service.weeklySummary(
            days: days,
            goals: GoalSnapshot(
                calorieTarget: 2_100,
                proteinTargetGrams: 120,
                stepTarget: 8_000,
                waterTargetLiters: 2,
                sleepTargetHours: 7
            )
        )

        XCTAssertEqual(summary.averageCaloriesIn, 2_000)
        XCTAssertEqual(summary.averageProtein, 130)
        XCTAssertEqual(summary.workoutMinutes, 245)
        let weightTrendKg = try XCTUnwrap(summary.weightTrendKg)
        XCTAssertEqual(weightTrendKg, -0.6, accuracy: 0.01)
        XCTAssertGreaterThan(summary.adherenceScore, 0.9)
        XCTAssertEqual(summary.disclaimer, SummaryService.wellnessDisclaimer)
    }
}
