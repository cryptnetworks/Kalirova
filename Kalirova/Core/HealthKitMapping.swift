import Foundation

public struct HealthKitWorkoutSampleDTO: Codable, Equatable, Sendable {
    public var id: UUID
    public var healthKitActivityType: String
    public var startedAt: Date
    public var endedAt: Date
    public var durationMinutes: Double
    public var totalEnergyKilocalories: Double?
    public var distanceMeters: Double?
    public var averageHeartRate: Int?
    public var sourceName: String

    public init(
        id: UUID = UUID(),
        healthKitActivityType: String,
        startedAt: Date,
        endedAt: Date,
        durationMinutes: Double,
        totalEnergyKilocalories: Double? = nil,
        distanceMeters: Double? = nil,
        averageHeartRate: Int? = nil,
        sourceName: String
    ) {
        self.id = id
        self.healthKitActivityType = healthKitActivityType
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
        self.totalEnergyKilocalories = totalEnergyKilocalories
        self.distanceMeters = distanceMeters
        self.averageHeartRate = averageHeartRate
        self.sourceName = sourceName
    }
}

public struct WorkoutImportResult: Codable, Equatable, Sendable {
    public var id: UUID
    public var input: WorkoutInput
    public var deviceReportedCalories: Double?
    public var sourceName: String
    public var startedAt: Date
    public var endedAt: Date

    public init(
        id: UUID,
        input: WorkoutInput,
        deviceReportedCalories: Double?,
        sourceName: String,
        startedAt: Date,
        endedAt: Date
    ) {
        self.id = id
        self.input = input
        self.deviceReportedCalories = deviceReportedCalories
        self.sourceName = sourceName
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public enum HealthKitMapping {
    public static func mapWorkout(_ sample: HealthKitWorkoutSampleDTO) -> WorkoutImportResult {
        WorkoutImportResult(
            id: sample.id,
            input: WorkoutInput(
                kind: mapActivityType(sample.healthKitActivityType),
                durationMinutes: sample.durationMinutes,
                averageHeartRate: sample.averageHeartRate,
                distanceMeters: sample.distanceMeters
            ),
            deviceReportedCalories: sample.totalEnergyKilocalories,
            sourceName: sample.sourceName,
            startedAt: sample.startedAt,
            endedAt: sample.endedAt
        )
    }

    public static func mapActivityType(_ activityType: String) -> WorkoutKind {
        let normalized = activityType
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")

        if normalized.contains("run") { return .running }
        if normalized.contains("walk") { return .walking }
        if normalized.contains("cycle") || normalized.contains("bik") { return .cycling }
        if normalized.contains("strength") || normalized.contains("functional") { return .strengthTraining }
        if normalized.contains("swim") { return .swimming }
        if normalized.contains("hik") { return .hiking }
        if normalized.contains("row") { return .rowing }
        if normalized.contains("yoga") { return .yoga }
        if normalized.contains("elliptical") { return .elliptical }
        if normalized.contains("workout") { return .workout }
        return .other
    }
}

