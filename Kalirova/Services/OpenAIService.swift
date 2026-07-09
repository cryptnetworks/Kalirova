import Foundation

struct OpenAIRequestPreview: Codable, Equatable, Sendable {
    var endpoint: String
    var model: String
    var purpose: String
    var payload: String
}

struct RestaurantMealEstimateRequest: Codable, Equatable, Sendable {
    var restaurantName: String
    var itemName: String
    var portionDescription: String
    var notes: String

    var mealInformation: [String: Any] {
        [
            "restaurantName": restaurantName,
            "itemName": itemName,
            "portionDescription": portionDescription,
            "notes": notes
        ]
    }
}

struct OpenAIMealAnalysis: Codable, Equatable, Sendable {
    var items: [OpenAIFoodItem]
    var totalCalories: Double
    var totalProteinGrams: Double
    var totalCarbohydrateGrams: Double
    var totalFatGrams: Double
    var totalFiberGrams: Double
    var totalSugarGrams: Double
    var totalSodiumMilligrams: Double
    var confidence: String
    var assumptions: [String]
    var suggestedServingCorrections: [String]
    var sourceNotes: [String]
    var disclaimer: String
}

struct OpenAIFoodItem: Codable, Equatable, Sendable {
    var name: String
    var servingDescription: String
    var calories: Double
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var fiberGrams: Double
    var sugarGrams: Double
    var sodiumMilligrams: Double
}

enum OpenAIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case noOutputText

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Add an OpenAI API key in Settings before sending."
        case .invalidResponse: "The OpenAI response could not be decoded."
        case .noOutputText: "The OpenAI response did not include output text."
        }
    }
}

final class OpenAIService: @unchecked Sendable {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func previewMealAnalysisPayload(mealText: String, model: String) throws -> OpenAIRequestPreview {
        let payload = try mealAnalysisPayload(mealText: mealText, model: model)
        return OpenAIRequestPreview(
            endpoint: endpoint.absoluteString,
            model: model,
            purpose: "Estimate nutrition from one user-provided meal description.",
            payload: try payload.prettyPrintedJSONString()
        )
    }

    func previewRestaurantMealEstimatePayload(request: RestaurantMealEstimateRequest, model: String) throws -> OpenAIRequestPreview {
        let payload = try restaurantMealEstimatePayload(request: request, model: model)
        return OpenAIRequestPreview(
            endpoint: endpoint.absoluteString,
            model: model,
            purpose: "Estimate restaurant meal nutrition from the meal information shown in the privacy confirmation.",
            payload: try payload.prettyPrintedJSONString()
        )
    }

    func previewRestaurantMealInformation(_ request: RestaurantMealEstimateRequest) throws -> String {
        try request.mealInformation.prettyPrintedJSONString()
    }

    func analyzeMeal(mealText: String, model: String, apiKey: String?) async throws -> OpenAIMealAnalysis {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: mealAnalysisPayload(mealText: mealText, model: model))

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw OpenAIServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let outputText = decoded.outputText else {
            throw OpenAIServiceError.noOutputText
        }

        guard let jsonData = outputText.data(using: .utf8) else {
            throw OpenAIServiceError.invalidResponse
        }

        return try JSONDecoder().decode(OpenAIMealAnalysis.self, from: jsonData)
    }

    func estimateRestaurantMeal(request: RestaurantMealEstimateRequest, model: String, apiKey: String?) async throws -> OpenAIMealAnalysis {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIServiceError.missingAPIKey
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: restaurantMealEstimatePayload(request: request, model: model))

        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw OpenAIServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let outputText = decoded.outputText else {
            throw OpenAIServiceError.noOutputText
        }

        guard let jsonData = outputText.data(using: .utf8) else {
            throw OpenAIServiceError.invalidResponse
        }

        return try JSONDecoder().decode(OpenAIMealAnalysis.self, from: jsonData)
    }

    private func mealAnalysisPayload(mealText: String, model: String) throws -> [String: Any] {
        [
            "model": model,
            "store": false,
            "reasoning": [
                "effort": "low"
            ],
            "input": [
                [
                    "role": "developer",
                    "content": [
                        [
                            "type": "input_text",
                            "text": "Estimate nutrition for wellness tracking only. Return JSON matching the schema. Do not provide medical advice."
                        ]
                    ]
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": "Meal: \(mealText)"
                        ]
                    ]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "meal_nutrition_estimate",
                    "strict": true,
                    "schema": mealAnalysisSchema
                ],
                "verbosity": "low"
            ]
        ]
    }

    private func restaurantMealEstimatePayload(request: RestaurantMealEstimateRequest, model: String) throws -> [String: Any] {
        [
            "model": model,
            "store": false,
            "reasoning": [
                "effort": "low"
            ],
            "input": [
                [
                    "role": "developer",
                    "content": [
                        [
                            "type": "input_text",
                            "text": """
                            Estimate restaurant meal nutrition for wellness tracking only. Use known restaurant nutrition information when it is generally available; otherwise make a careful estimate from the restaurant, item, portion, and modifications. Return JSON matching the schema. Make assumptions explicit, include source or estimation notes, and state that restaurant nutrition may vary by preparation and portion size. Do not provide medical advice.
                            """
                        ]
                    ]
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": "Restaurant meal information: \(try request.mealInformation.prettyPrintedJSONString())"
                        ]
                    ]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "restaurant_meal_nutrition_estimate",
                    "strict": true,
                    "schema": mealAnalysisSchema
                ],
                "verbosity": "low"
            ]
        ]
    }

    private var mealAnalysisSchema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "required": [
                "items",
                "totalCalories",
                "totalProteinGrams",
                "totalCarbohydrateGrams",
                "totalFatGrams",
                "totalFiberGrams",
                "totalSugarGrams",
                "totalSodiumMilligrams",
                "confidence",
                "assumptions",
                "suggestedServingCorrections",
                "sourceNotes",
                "disclaimer"
            ],
            "properties": [
                "items": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                            "name",
                            "servingDescription",
                            "calories",
                            "proteinGrams",
                            "carbohydrateGrams",
                            "fatGrams",
                            "fiberGrams",
                            "sugarGrams",
                            "sodiumMilligrams"
                        ],
                        "properties": [
                            "name": ["type": "string"],
                            "servingDescription": ["type": "string"],
                            "calories": ["type": "number"],
                            "proteinGrams": ["type": "number"],
                            "carbohydrateGrams": ["type": "number"],
                            "fatGrams": ["type": "number"],
                            "fiberGrams": ["type": "number"],
                            "sugarGrams": ["type": "number"],
                            "sodiumMilligrams": ["type": "number"]
                        ]
                    ]
                ],
                "totalCalories": ["type": "number"],
                "totalProteinGrams": ["type": "number"],
                "totalCarbohydrateGrams": ["type": "number"],
                "totalFatGrams": ["type": "number"],
                "totalFiberGrams": ["type": "number"],
                "totalSugarGrams": ["type": "number"],
                "totalSodiumMilligrams": ["type": "number"],
                "confidence": ["type": "string", "enum": ["low", "medium", "high"]],
                "assumptions": ["type": "array", "items": ["type": "string"]],
                "suggestedServingCorrections": ["type": "array", "items": ["type": "string"]],
                "sourceNotes": ["type": "array", "items": ["type": "string"]],
                "disclaimer": ["type": "string"]
            ]
        ]
    }
}

private struct OpenAIResponse: Decodable {
    var output: [OutputItem]

    var outputText: String? {
        output
            .compactMap(\.content)
            .flatMap { $0 }
            .first { $0.type == "output_text" }?
            .text
    }

    struct OutputItem: Decodable {
        var content: [ContentItem]?
    }

    struct ContentItem: Decodable {
        var type: String
        var text: String?
    }
}

private extension Dictionary where Key == String, Value == Any {
    func prettyPrintedJSONString() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
