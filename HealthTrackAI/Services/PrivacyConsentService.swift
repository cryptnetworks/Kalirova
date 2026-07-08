import Foundation

struct PrivacyConsentService {
    func weeklySummaryPayloadPreview(days: [DailyHealthSnapshot], model: String) throws -> OpenAIRequestPreview {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let payload = WeeklySummaryAIPayload(
            disclaimer: SummaryService.wellnessDisclaimer,
            includedFields: [
                "date",
                "calories",
                "protein",
                "active energy",
                "workout minutes",
                "steps",
                "water",
                "sleep",
                "body mass trend"
            ],
            excludedFields: [
                "raw HealthKit samples",
                "full HealthKit history",
                "notes unrelated to the selected week",
                "API keys"
            ],
            days: days
        )

        let data = try encoder.encode(payload)
        let payloadString = String(data: data, encoding: .utf8) ?? "{}"

        return OpenAIRequestPreview(
            endpoint: "https://api.openai.com/v1/responses",
            model: model,
            purpose: "Generate an optional coaching-style weekly wellness summary from date-bounded statistics.",
            payload: payloadString
        )
    }
}

private struct WeeklySummaryAIPayload: Codable {
    var disclaimer: String
    var includedFields: [String]
    var excludedFields: [String]
    var days: [DailyHealthSnapshot]
}

