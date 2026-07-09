import Foundation
#if canImport(OSLog)
import OSLog
#endif

public struct NutrientTotals: Codable, Equatable, Sendable {
    public var calories: Double
    public var proteinGrams: Double
    public var carbohydrateGrams: Double
    public var fatGrams: Double
    public var fiberGrams: Double
    public var sugarGrams: Double
    public var sodiumMilligrams: Double

    public init(
        calories: Double = 0,
        proteinGrams: Double = 0,
        carbohydrateGrams: Double = 0,
        fatGrams: Double = 0,
        fiberGrams: Double = 0,
        sugarGrams: Double = 0,
        sodiumMilligrams: Double = 0
    ) {
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.sugarGrams = sugarGrams
        self.sodiumMilligrams = sodiumMilligrams
    }

    public static func + (lhs: NutrientTotals, rhs: NutrientTotals) -> NutrientTotals {
        NutrientTotals(
            calories: lhs.calories + rhs.calories,
            proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
            carbohydrateGrams: lhs.carbohydrateGrams + rhs.carbohydrateGrams,
            fatGrams: lhs.fatGrams + rhs.fatGrams,
            fiberGrams: lhs.fiberGrams + rhs.fiberGrams,
            sugarGrams: lhs.sugarGrams + rhs.sugarGrams,
            sodiumMilligrams: lhs.sodiumMilligrams + rhs.sodiumMilligrams
        )
    }
}

public struct ParsedFoodItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var quantityDescription: String
    public var nutrients: NutrientTotals
    public var assumptions: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        quantityDescription: String,
        nutrients: NutrientTotals,
        assumptions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.quantityDescription = quantityDescription
        self.nutrients = nutrients
        self.assumptions = assumptions
    }
}

public struct MealNutritionEstimate: Codable, Equatable, Sendable {
    public var originalText: String
    public var items: [ParsedFoodItem]
    public var totals: NutrientTotals
    public var confidence: EstimateConfidence
    public var assumptions: [String]

    public init(
        originalText: String,
        items: [ParsedFoodItem],
        totals: NutrientTotals,
        confidence: EstimateConfidence,
        assumptions: [String]
    ) {
        self.originalText = originalText
        self.items = items
        self.totals = totals
        self.confidence = confidence
        self.assumptions = assumptions
    }
}

public final class NutritionService: Sendable {
    public init() {}

    public func parseLocalMealDescription(_ text: String) -> MealNutritionEstimate {
        let normalized = text.lowercased()
        let matchedItems = knownFoods.compactMap { food -> ParsedFoodItem? in
            guard normalized.contains(food.key) else { return nil }
            let quantity = quantityMultiplier(near: food.key, in: normalized)
            return ParsedFoodItem(
                name: food.displayName,
                quantityDescription: quantity.description,
                nutrients: food.nutrients.scaled(by: quantity.value),
                assumptions: ["Local fallback estimate based on common serving size."]
            )
        }

        if matchedItems.isEmpty {
            return MealNutritionEstimate(
                originalText: text,
                items: [],
                totals: NutrientTotals(),
                confidence: .low,
                assumptions: ["No known local foods matched. Use manual entry or optional AI parsing."]
            )
        }

        let totals = matchedItems.reduce(NutrientTotals()) { $0 + $1.nutrients }.rounded()
        let confidence: EstimateConfidence = matchedItems.count >= 2 ? .medium : .low

        return MealNutritionEstimate(
            originalText: text,
            items: matchedItems,
            totals: totals,
            confidence: confidence,
            assumptions: matchedItems.flatMap(\.assumptions)
        )
    }

    private func quantityMultiplier(near key: String, in text: String) -> (value: Double, description: String) {
        let tokens = text
            .replacingOccurrences(of: ",", with: " ")
            .split(separator: " ")
            .map(String.init)

        guard let index = tokens.firstIndex(where: { $0.contains(key) || key.contains($0) }) else {
            return (1, "1 serving")
        }

        guard index > tokens.startIndex else {
            return (1, "1 serving")
        }

        let previousIndex = tokens.index(before: index)
        let previous = tokens[previousIndex]
        if let number = Double(previous) {
            return (max(0.25, number), "\(number.cleanDescription) servings")
        }

        return (1, "1 serving")
    }

    private let knownFoods: [KnownFood] = [
        KnownFood(
            key: "egg",
            displayName: "Egg",
            nutrients: NutrientTotals(calories: 72, proteinGrams: 6.3, carbohydrateGrams: 0.4, fatGrams: 4.8, sodiumMilligrams: 71)
        ),
        KnownFood(
            key: "toast",
            displayName: "Toast",
            nutrients: NutrientTotals(calories: 80, proteinGrams: 3, carbohydrateGrams: 15, fatGrams: 1, fiberGrams: 1.2, sugarGrams: 1.4, sodiumMilligrams: 150)
        ),
        KnownFood(
            key: "butter",
            displayName: "Butter",
            nutrients: NutrientTotals(calories: 102, fatGrams: 11.5, sodiumMilligrams: 91)
        ),
        KnownFood(
            key: "coffee",
            displayName: "Coffee",
            nutrients: NutrientTotals(calories: 2)
        ),
        KnownFood(
            key: "milk",
            displayName: "Milk",
            nutrients: NutrientTotals(calories: 61, proteinGrams: 3.2, carbohydrateGrams: 4.8, fatGrams: 3.3, sugarGrams: 5.1, sodiumMilligrams: 43)
        ),
        KnownFood(
            key: "chicken",
            displayName: "Chicken Breast",
            nutrients: NutrientTotals(calories: 165, proteinGrams: 31, fatGrams: 3.6, sodiumMilligrams: 74)
        ),
        KnownFood(
            key: "rice",
            displayName: "Rice",
            nutrients: NutrientTotals(calories: 206, proteinGrams: 4.3, carbohydrateGrams: 45, fatGrams: 0.4, fiberGrams: 0.6)
        ),
        KnownFood(
            key: "banana",
            displayName: "Banana",
            nutrients: NutrientTotals(calories: 105, proteinGrams: 1.3, carbohydrateGrams: 27, fatGrams: 0.4, fiberGrams: 3.1, sugarGrams: 14.4, sodiumMilligrams: 1)
        )
    ]
}

private struct KnownFood: Sendable {
    var key: String
    var displayName: String
    var nutrients: NutrientTotals
}

private extension NutrientTotals {
    func scaled(by multiplier: Double) -> NutrientTotals {
        NutrientTotals(
            calories: calories * multiplier,
            proteinGrams: proteinGrams * multiplier,
            carbohydrateGrams: carbohydrateGrams * multiplier,
            fatGrams: fatGrams * multiplier,
            fiberGrams: fiberGrams * multiplier,
            sugarGrams: sugarGrams * multiplier,
            sodiumMilligrams: sodiumMilligrams * multiplier
        ).rounded()
    }

    func rounded() -> NutrientTotals {
        NutrientTotals(
            calories: calories.rounded(toPlaces: 1),
            proteinGrams: proteinGrams.rounded(toPlaces: 1),
            carbohydrateGrams: carbohydrateGrams.rounded(toPlaces: 1),
            fatGrams: fatGrams.rounded(toPlaces: 1),
            fiberGrams: fiberGrams.rounded(toPlaces: 1),
            sugarGrams: sugarGrams.rounded(toPlaces: 1),
            sodiumMilligrams: sodiumMilligrams.rounded(toPlaces: 0)
        )
    }
}

private extension Double {
    var cleanDescription: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(self)
    }

    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}

public protocol AppErrorConvertible {
    var appError: AppError { get }
}

public enum AppErrorSeverity: String, Codable, Equatable, Sendable {
    case info
    case warning
    case error
}

public struct AppError: LocalizedError, Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var message: String
    public var recoverySuggestion: String?
    public var technicalDetails: String?
    public var severity: AppErrorSeverity

    public var errorDescription: String? { message }
    public var failureReason: String? { title }

    public init(
        title: String,
        message: String,
        recoverySuggestion: String? = nil,
        technicalDetails: String? = nil,
        severity: AppErrorSeverity = .error,
        id: String = UUID().uuidString
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
        self.technicalDetails = technicalDetails
        self.severity = severity
    }

    public static func validation(
        _ message: String,
        field: String,
        recoverySuggestion: String? = nil
    ) -> AppError {
        AppError(
            title: "\(field) needs attention",
            message: message,
            recoverySuggestion: recoverySuggestion,
            severity: .warning,
            id: "validation-\(field)-\(message)"
        )
    }

    public static var missingAPIKey: AppError {
        AppError(
            title: "OpenAI API key missing",
            message: "Add an OpenAI API key in Profile before using AI Search.",
            recoverySuggestion: "Open Profile, save your API key in Keychain, then try again.",
            id: "missing-api-key"
        )
    }

    public static var invalidAPIKey: AppError {
        AppError(
            title: "OpenAI API key rejected",
            message: "OpenAI rejected the saved API key.",
            recoverySuggestion: "Check that the key is current, has access to the selected model, and was pasted without extra spaces.",
            id: "invalid-api-key"
        )
    }

    public static var networkUnavailable: AppError {
        AppError(
            title: "Network unavailable",
            message: "Kalirova could not reach the network.",
            recoverySuggestion: "Check Wi-Fi or cellular service, then try again.",
            id: "network-unavailable"
        )
    }

    public static var timeout: AppError {
        AppError(
            title: "Request timed out",
            message: "The request took too long to complete.",
            recoverySuggestion: "Try again in a moment.",
            id: "request-timeout"
        )
    }

    public static var rateLimited: AppError {
        AppError(
            title: "Too many requests",
            message: "The service is temporarily rate limiting requests.",
            recoverySuggestion: "Wait a minute, then try again.",
            id: "rate-limited"
        )
    }

    public static var serverUnavailable: AppError {
        AppError(
            title: "Service unavailable",
            message: "The service is temporarily unavailable.",
            recoverySuggestion: "Try again later.",
            id: "server-unavailable"
        )
    }

    public static func saveFailed(context: String) -> AppError {
        AppError(
            title: "Could not save",
            message: "\(context) could not be saved on this device.",
            recoverySuggestion: "Try again. If it keeps happening, restart the app and check available device storage.",
            id: "save-failed-\(context)"
        )
    }

    public static func loadFailed(context: String) -> AppError {
        AppError(
            title: "Could not load",
            message: "\(context) could not be loaded.",
            recoverySuggestion: "Try again. If it keeps happening, restart the app.",
            id: "load-failed-\(context)"
        )
    }

    public static func deleteFailed(context: String) -> AppError {
        AppError(
            title: "Could not delete",
            message: "\(context) could not be deleted.",
            recoverySuggestion: "Try again before making more changes.",
            id: "delete-failed-\(context)"
        )
    }

    public static func decodingFailed(context: String) -> AppError {
        AppError(
            title: "Could not read response",
            message: "\(context) was returned in a format Kalirova could not read.",
            recoverySuggestion: "Try again. If this repeats, use manual entry for now.",
            id: "decoding-failed-\(context)"
        )
    }

    public static func permissionDenied(context: String) -> AppError {
        AppError(
            title: "Permission needed",
            message: "\(context) permission was not granted.",
            recoverySuggestion: "Review permissions in Settings, then try again.",
            id: "permission-denied-\(context)"
        )
    }

    public static func exportFailed(context: String) -> AppError {
        AppError(
            title: "Export unavailable",
            message: "\(context) could not be prepared for export.",
            recoverySuggestion: "Try again after restarting the app.",
            id: "export-failed-\(context)"
        )
    }

    public static func unavailable(_ context: String) -> AppError {
        AppError(
            title: "Unavailable",
            message: "\(context) is not available in this build or on this device.",
            recoverySuggestion: "Check device support and app settings.",
            id: "unavailable-\(context)"
        )
    }

    public static func unknown(context: String = "This action") -> AppError {
        AppError(
            title: "Something went wrong",
            message: "\(context) could not be completed.",
            recoverySuggestion: "Try again. If the issue continues, restart the app.",
            id: "unknown-\(context)"
        )
    }
}

public enum ErrorMessageMapper {
    public static func map(
        _ error: Error,
        fallback: AppError = .unknown(),
        technicalContext: String? = nil
    ) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let convertible = error as? AppErrorConvertible {
            return appErrorWithDetails(convertible.appError, error: error, technicalContext: technicalContext)
        }

        if let urlError = error as? URLError {
            return appErrorWithDetails(map(urlError), error: error, technicalContext: technicalContext)
        }

        if error is DecodingError {
            let decodingError = fallback.title == "Could not read response"
                ? fallback
                : AppError.decodingFailed(context: fallbackContext(from: fallback))
            return appErrorWithDetails(decodingError, error: error, technicalContext: technicalContext)
        }

        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            return appErrorWithDetails(fallback, error: error, technicalContext: technicalContext)
        }

        let lowercasedDescription = error.localizedDescription.lowercased()
        if lowercasedDescription.contains("api key") && lowercasedDescription.contains("missing") {
            return appErrorWithDetails(.missingAPIKey, error: error, technicalContext: technicalContext)
        }
        if lowercasedDescription.contains("rate limit") || lowercasedDescription.contains("too many requests") {
            return appErrorWithDetails(.rateLimited, error: error, technicalContext: technicalContext)
        }
        if lowercasedDescription.contains("permission") || lowercasedDescription.contains("authorization denied") {
            return appErrorWithDetails(.permissionDenied(context: fallbackContext(from: fallback)), error: error, technicalContext: technicalContext)
        }

        return appErrorWithDetails(fallback, error: error, technicalContext: technicalContext)
    }

    private static func map(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .networkUnavailable
        case .timedOut:
            return .timeout
        case .userAuthenticationRequired, .userCancelledAuthentication:
            return .permissionDenied(context: "Network")
        case .badServerResponse:
            return .serverUnavailable
        default:
            return .unknown(context: "Network request")
        }
    }

    private static func appErrorWithDetails(_ appError: AppError, error: Error, technicalContext: String?) -> AppError {
        var updated = appError
        let nsError = error as NSError
        let details = [
            technicalContext,
            "Type: \(String(reflecting: type(of: error)))",
            "Domain: \(nsError.domain)",
            "Code: \(nsError.code)"
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        updated.technicalDetails = details.isEmpty ? appError.technicalDetails : details
        return updated
    }

    private static func fallbackContext(from appError: AppError) -> String {
        if appError.title == "Something went wrong" {
            return "This action"
        }
        return appError.title
    }
}

public enum AppErrorLogger {
    public static func log(_ error: AppError, source: String) {
        #if canImport(OSLog)
        if #available(iOS 14.0, macOS 11.0, *) {
            Logger(subsystem: "com.kalirova.app", category: "errors").error(
                "User-facing error in \(source, privacy: .public): \(error.title, privacy: .public) [\(error.id, privacy: .public)]"
            )
        }
        #endif
    }
}
