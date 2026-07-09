import Foundation

public enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case female
    case male
    case notSpecified
}

public enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case athlete
}

public enum UnitSystem: String, Codable, CaseIterable, Identifiable, Sendable {
    case metric
    case imperial

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .metric: "Metric"
        case .imperial: "Imperial"
        }
    }
}

public enum UnitConverter {
    public static func kilograms(fromPounds pounds: Double) -> Double {
        pounds / 2.204_622_621_8
    }

    public static func pounds(fromKilograms kilograms: Double) -> Double {
        kilograms * 2.204_622_621_8
    }

    public static func centimeters(fromFeet feet: Double, inches: Double) -> Double {
        ((feet * 12) + inches) * 2.54
    }

    public static func totalInches(fromCentimeters centimeters: Double) -> Double {
        centimeters / 2.54
    }

    public static func feetAndInches(fromCentimeters centimeters: Double) -> (feet: Int, inches: Double) {
        let totalInches = totalInches(fromCentimeters: centimeters)
        let feet = Int(totalInches / 12)
        return (feet, totalInches - Double(feet * 12))
    }

    public static func kilometers(fromMiles miles: Double) -> Double {
        miles * 1.609_344
    }

    public static func miles(fromKilometers kilometers: Double) -> Double {
        kilometers / 1.609_344
    }
}

public struct BMIEstimate: Codable, Equatable, Sendable {
    public var value: Double
    public var category: String

    public init(value: Double, category: String) {
        self.value = value
        self.category = category
    }

    public static func calculate(heightCentimeters: Double, bodyMassKg: Double) -> BMIEstimate? {
        guard heightCentimeters > 0, bodyMassKg > 0 else { return nil }
        let meters = heightCentimeters / 100
        let value = bodyMassKg / (meters * meters)
        let roundedValue = value.rounded(toPlaces: 1)

        let category: String
        switch roundedValue {
        case ..<18.5:
            category = "Underweight"
        case 18.5..<25:
            category = "Healthy weight"
        case 25..<30:
            category = "Overweight"
        default:
            category = "Obesity"
        }

        return BMIEstimate(value: roundedValue, category: category)
    }
}

public enum WorkoutKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case walking
    case running
    case cycling
    case strengthTraining
    case swimming
    case hiking
    case rowing
    case yoga
    case elliptical
    case workout
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .walking: "Walking"
        case .running: "Running"
        case .cycling: "Cycling"
        case .strengthTraining: "Strength Training"
        case .swimming: "Swimming"
        case .hiking: "Hiking"
        case .rowing: "Rowing"
        case .yoga: "Yoga"
        case .elliptical: "Elliptical"
        case .workout: "Workout"
        case .other: "Other"
        }
    }

    public var baseMET: Double {
        switch self {
        case .walking: 3.5
        case .running: 9.8
        case .cycling: 7.5
        case .strengthTraining: 5.0
        case .swimming: 8.0
        case .hiking: 6.0
        case .rowing: 7.0
        case .yoga: 2.5
        case .elliptical: 5.5
        case .workout: 5.0
        case .other: 3.5
        }
    }
}

public enum PerceivedEffort: String, Codable, CaseIterable, Sendable {
    case easy
    case moderate
    case hard
    case maximal

    public var multiplier: Double {
        switch self {
        case .easy: 0.9
        case .moderate: 1.0
        case .hard: 1.15
        case .maximal: 1.3
        }
    }
}

public enum EstimateConfidence: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

public struct UserProfileSnapshot: Codable, Equatable, Sendable {
    public var ageYears: Int?
    public var sex: BiologicalSex
    public var bodyMassKg: Double?
    public var restingHeartRate: Int?
    public var maxHeartRate: Int?
    public var activityLevel: ActivityLevel

    public init(
        ageYears: Int? = nil,
        sex: BiologicalSex = .notSpecified,
        bodyMassKg: Double? = nil,
        restingHeartRate: Int? = nil,
        maxHeartRate: Int? = nil,
        activityLevel: ActivityLevel = .moderatelyActive
    ) {
        self.ageYears = ageYears
        self.sex = sex
        self.bodyMassKg = bodyMassKg
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
        self.activityLevel = activityLevel
    }
}

public struct WorkoutInput: Codable, Equatable, Sendable {
    public var kind: WorkoutKind
    public var durationMinutes: Double
    public var bodyMassKg: Double?
    public var averageHeartRate: Int?
    public var distanceMeters: Double?
    public var elevationGainMeters: Double?
    public var perceivedEffort: PerceivedEffort?

    public init(
        kind: WorkoutKind,
        durationMinutes: Double,
        bodyMassKg: Double? = nil,
        averageHeartRate: Int? = nil,
        distanceMeters: Double? = nil,
        elevationGainMeters: Double? = nil,
        perceivedEffort: PerceivedEffort? = nil
    ) {
        self.kind = kind
        self.durationMinutes = durationMinutes
        self.bodyMassKg = bodyMassKg
        self.averageHeartRate = averageHeartRate
        self.distanceMeters = distanceMeters
        self.elevationGainMeters = elevationGainMeters
        self.perceivedEffort = perceivedEffort
    }
}

public struct CalorieEstimate: Codable, Equatable, Sendable {
    public var calories: Double
    public var confidence: EstimateConfidence
    public var algorithmVersion: String
    public var method: String
    public var met: Double

    public init(
        calories: Double,
        confidence: EstimateConfidence,
        algorithmVersion: String,
        method: String,
        met: Double
    ) {
        self.calories = calories
        self.confidence = confidence
        self.algorithmVersion = algorithmVersion
        self.method = method
        self.met = met
    }
}

public final class CalorieBurnEstimator: Sendable {
    public static let algorithmVersion = "calorie-burn-v1"

    public init() {}

    public func estimate(workout: WorkoutInput, profile: UserProfileSnapshot) -> CalorieEstimate {
        guard workout.durationMinutes > 0 else {
            return CalorieEstimate(
                calories: 0,
                confidence: .low,
                algorithmVersion: Self.algorithmVersion,
                method: "invalid-duration",
                met: 0
            )
        }

        let bodyMassKg = workout.bodyMassKg ?? profile.bodyMassKg ?? 70
        let hasKnownBodyMass = workout.bodyMassKg != nil || profile.bodyMassKg != nil
        let met = adjustedMET(for: workout, profile: profile)
        let calories = met * 3.5 * bodyMassKg / 200 * workout.durationMinutes

        let hasUsefulWorkoutType = workout.kind != .other
        let confidence: EstimateConfidence
        let method: String

        if workout.averageHeartRate != nil, hasKnownBodyMass, hasUsefulWorkoutType {
            confidence = .high
            method = "heart-rate-zone-met"
        } else if hasKnownBodyMass, hasUsefulWorkoutType {
            confidence = .medium
            method = "met"
        } else {
            confidence = .low
            method = "generic-met"
        }

        return CalorieEstimate(
            calories: calories.rounded(toPlaces: 1),
            confidence: confidence,
            algorithmVersion: Self.algorithmVersion,
            method: method,
            met: met.rounded(toPlaces: 2)
        )
    }

    private func adjustedMET(for workout: WorkoutInput, profile: UserProfileSnapshot) -> Double {
        var met = workout.kind.baseMET
        met *= speedMultiplier(for: workout)
        met *= elevationMultiplier(for: workout)
        met *= workout.perceivedEffort?.multiplier ?? 1

        if let averageHeartRate = workout.averageHeartRate {
            met *= heartRateMultiplier(
                averageHeartRate: averageHeartRate,
                profile: profile
            )
        }

        return max(1, met)
    }

    private func speedMultiplier(for workout: WorkoutInput) -> Double {
        guard
            let distanceMeters = workout.distanceMeters,
            workout.durationMinutes > 0
        else {
            return 1
        }

        let hours = workout.durationMinutes / 60
        let kilometersPerHour = (distanceMeters / 1_000) / hours

        switch workout.kind {
        case .running:
            if kilometersPerHour >= 13 { return 1.2 }
            if kilometersPerHour >= 10 { return 1.08 }
            if kilometersPerHour < 7 { return 0.9 }
            return 1
        case .walking, .hiking:
            if kilometersPerHour >= 6.5 { return 1.15 }
            if kilometersPerHour < 3 { return 0.85 }
            return 1
        case .cycling:
            if kilometersPerHour >= 30 { return 1.25 }
            if kilometersPerHour >= 22 { return 1.1 }
            if kilometersPerHour < 12 { return 0.85 }
            return 1
        default:
            return 1
        }
    }

    private func elevationMultiplier(for workout: WorkoutInput) -> Double {
        guard
            let elevationGainMeters = workout.elevationGainMeters,
            let distanceMeters = workout.distanceMeters,
            distanceMeters > 0,
            [.walking, .running, .hiking, .cycling].contains(workout.kind)
        else {
            return 1
        }

        let grade = elevationGainMeters / distanceMeters
        if grade >= 0.08 { return 1.2 }
        if grade >= 0.04 { return 1.1 }
        return 1
    }

    private func heartRateMultiplier(averageHeartRate: Int, profile: UserProfileSnapshot) -> Double {
        let restingHeartRate = Double(profile.restingHeartRate ?? 60)
        let maxHeartRate = Double(profile.maxHeartRate ?? estimatedMaxHeartRate(ageYears: profile.ageYears))
        guard maxHeartRate > restingHeartRate else { return 1 }

        let reserve = maxHeartRate - restingHeartRate
        let intensity = (Double(averageHeartRate) - restingHeartRate) / reserve

        switch intensity {
        case ..<0.5:
            return 0.9
        case 0.5..<0.7:
            return 1.0
        case 0.7..<0.85:
            return 1.18
        default:
            return 1.35
        }
    }

    private func estimatedMaxHeartRate(ageYears: Int?) -> Int {
        guard let ageYears else { return 180 }
        return max(120, 220 - ageYears)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}
