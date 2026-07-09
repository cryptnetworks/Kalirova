import Foundation
import Combine
import OSLog

#if canImport(HealthKit)
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    @Published private(set) var authorizationStatusText = "Not requested"

    private let logger = Logger(subsystem: "com.kalirova.app", category: "healthkit")
    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            authorizationStatusText = "Health data is not available on this device."
            logger.info("HealthKit authorization skipped because health data is unavailable")
            return
        }

        let readTypes = requiredReadTypes()
        logger.info("Requesting HealthKit authorization")

        let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            store.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }

        authorizationStatusText = success ? "Authorized" : "Authorization denied"
        logger.info("HealthKit authorization finished with success: \(success, privacy: .public)")
    }

    func importedWorkouts(from startDate: Date, to endDate: Date, limit: Int = HKObjectQueryNoLimit) async throws -> [HealthKitWorkoutSampleDTO] {
        try Task.checkCancellation()
        logger.info("Starting HealthKit workout import")

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate, .strictEndDate]
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HealthKitWorkoutSampleDTO], Error>) in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    HealthKitWorkoutSampleDTO(
                        healthKitActivityType: Self.activityTypeName(workout.workoutActivityType),
                        startedAt: workout.startDate,
                        endedAt: workout.endDate,
                        durationMinutes: workout.duration / 60,
                        totalEnergyKilocalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                        distanceMeters: workout.totalDistance?.doubleValue(for: .meter()),
                        averageHeartRate: nil,
                        sourceName: workout.sourceRevision.source.name
                    )
                }

                continuation.resume(returning: workouts)
            }

            store.execute(query)
        }

        try Task.checkCancellation()
        logger.info("HealthKit workout import returned \(workouts.count, privacy: .public) workouts")
        return workouts
    }

    private func requiredReadTypes() -> Set<HKObjectType> {
        var types = Set<HKObjectType>()
        types.insert(HKObjectType.workoutType())

        [
            HKQuantityTypeIdentifier.heartRate,
            .stepCount,
            .distanceWalkingRunning,
            .distanceCycling,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .bodyMass,
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryWater,
            .appleExerciseTime
        ].compactMap { HKQuantityType.quantityType(forIdentifier: $0) }.forEach { types.insert($0) }

        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        return types
    }

    private nonisolated static func activityTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: "running"
        case .walking: "walking"
        case .cycling: "cycling"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "strengthTraining"
        case .swimming: "swimming"
        case .hiking: "hiking"
        case .rowing: "rowing"
        case .yoga: "yoga"
        case .elliptical: "elliptical"
        default: "workout"
        }
    }
}
#else
@MainActor
final class HealthKitService: ObservableObject {
    @Published private(set) var authorizationStatusText = "HealthKit unavailable"

    var isHealthDataAvailable: Bool { false }

    func requestAuthorization() async throws {
        authorizationStatusText = "HealthKit is unavailable in this environment."
    }

    func importedWorkouts(from startDate: Date, to endDate: Date, limit: Int = 100) async throws -> [HealthKitWorkoutSampleDTO] {
        []
    }
}
#endif
