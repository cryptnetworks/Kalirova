import XCTest
@testable import Kalirova

final class KeychainServiceTests: XCTestCase {
    private var service: KeychainService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        service = KeychainService(
            service: "com.michaeldesocio.kalirova.tests.\(UUID().uuidString)",
            openAIAccount: "openai_api_key"
        )
        try service.deleteOpenAIAPIKey()
    }

    override func tearDownWithError() throws {
        try service.deleteOpenAIAPIKey()
        service = nil
        try super.tearDownWithError()
    }

    func testSaveAndLoadOpenAIAPIKey() throws {
        try service.saveOpenAIAPIKey("test-key-value-1111")

        XCTAssertEqual(try service.loadOpenAIAPIKey(), "test-key-value-1111")
    }

    func testUpdateOpenAIAPIKey() throws {
        try service.saveOpenAIAPIKey("test-key-value-1111")
        try service.saveOpenAIAPIKey("test-key-value-2222")

        XCTAssertEqual(try service.loadOpenAIAPIKey(), "test-key-value-2222")
    }

    func testDeleteOpenAIAPIKey() throws {
        try service.saveOpenAIAPIKey("test-key-value-1111")
        try service.deleteOpenAIAPIKey()

        XCTAssertNil(try service.loadOpenAIAPIKey())
    }

    func testMaskedAPIKeyDoesNotRevealFullValue() {
        let masked = KeychainService.maskedAPIKey("test-key-value-1111")

        XCTAssertEqual(masked, "Stored key ...1111")
        XCTAssertFalse(masked.contains("test-key-value"))
    }
}
