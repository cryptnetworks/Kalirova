import XCTest
@testable import HealthTrackAICore

final class NutritionServiceTests: XCTestCase {
    func testLocalMealParserReturnsStructuredNutrition() {
        let service = NutritionService()
        let estimate = service.parseLocalMealDescription("2 eggs, toast with butter, coffee with milk")

        XCTAssertEqual(estimate.confidence, .medium)
        XCTAssertGreaterThanOrEqual(estimate.items.count, 5)
        XCTAssertGreaterThan(estimate.totals.calories, 300)
        XCTAssertGreaterThan(estimate.totals.proteinGrams, 10)
    }

    func testUnknownMealAsksForManualOrAIParsing() {
        let service = NutritionService()
        let estimate = service.parseLocalMealDescription("family recipe")

        XCTAssertEqual(estimate.confidence, .low)
        XCTAssertTrue(estimate.items.isEmpty)
        XCTAssertTrue(estimate.assumptions.first?.contains("manual entry") == true)
    }
}

