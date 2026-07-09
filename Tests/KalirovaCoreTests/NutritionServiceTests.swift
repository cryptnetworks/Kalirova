import XCTest
@testable import KalirovaCore

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

    func testErrorMapperUsesConvertibleAppError() {
        let mapped = ErrorMessageMapper.map(TestMissingAPIKeyError())

        XCTAssertEqual(mapped.id, AppError.missingAPIKey.id)
        XCTAssertEqual(mapped.title, "OpenAI API key missing")
        XCTAssertNotNil(mapped.technicalDetails)
    }

    func testErrorMapperMapsNetworkTimeout() {
        let mapped = ErrorMessageMapper.map(
            URLError(.timedOut),
            fallback: .unknown(context: "AI meal estimate"),
            technicalContext: "Unit test timeout"
        )

        XCTAssertEqual(mapped.id, AppError.timeout.id)
        XCTAssertEqual(mapped.recoverySuggestion, "Try again in a moment.")
        XCTAssertTrue(mapped.technicalDetails?.contains("Unit test timeout") == true)
    }

    func testErrorMapperMapsDecodingFailure() {
        struct Payload: Decodable {
            var value: Int
        }

        let data = Data(#"{"value":"wrong"}"#.utf8)

        do {
            _ = try JSONDecoder().decode(Payload.self, from: data)
            XCTFail("Expected decoding to fail")
        } catch {
            let mapped = ErrorMessageMapper.map(error, fallback: .decodingFailed(context: "Test payload"))
            XCTAssertEqual(mapped.title, "Could not read response")
            XCTAssertTrue(mapped.message.contains("Test payload"))
        }
    }

    func testValidationErrorIncludesRecoveryAndWarningSeverity() {
        let error = AppError.validation(
            "Weight must be greater than zero.",
            field: "Weight",
            recoverySuggestion: "Enter your current weight."
        )

        XCTAssertEqual(error.severity, .warning)
        XCTAssertEqual(error.title, "Weight needs attention")
        XCTAssertEqual(error.recoverySuggestion, "Enter your current weight.")
    }
}

private struct TestMissingAPIKeyError: Error, AppErrorConvertible {
    var appError: AppError { .missingAPIKey }
}
