import Foundation
import OSLog
import SwiftData
import SwiftUI

enum PersistenceServiceError: LocalizedError {
    case iCloudCapabilityUnavailable
    case localStoreUnavailable

    var errorDescription: String? {
        switch self {
        case .iCloudCapabilityUnavailable:
            "iCloud Backup is disabled for this local development build. Re-enable the iCloud capability and ENABLE_ICLOUD_BACKUP build flag with a paid Apple Developer account."
        case .localStoreUnavailable:
            "Local storage is temporarily unavailable. Kalirova started with temporary in-memory storage."
        }
    }
}

extension PersistenceServiceError: AppErrorConvertible {
    var appError: AppError {
        switch self {
        case .iCloudCapabilityUnavailable:
            .unavailable("iCloud Backup")
        case .localStoreUnavailable:
            AppError(
                title: "Local storage unavailable",
                message: "Kalirova could not open the local database and started with temporary storage.",
                recoverySuggestion: "Do not enter important data until the app can save normally. Restart the app and check available device storage.",
                id: "local-store-unavailable"
            )
        }
    }
}

@MainActor
final class PersistenceService: ObservableObject {
    static let iCloudBackupEnabledKey = "iCloudBackupEnabled"
    static let iCloudContainerIdentifier = "iCloud.com.kalirova.app"
    static var isICloudBackupCapabilityEnabled: Bool {
        #if ENABLE_ICLOUD_BACKUP
        true
        #else
        false
        #endif
    }

    @Published private(set) var modelContainer: ModelContainer
    @Published private(set) var startupError: AppError?

    private static let logger = Logger(subsystem: "com.kalirova.app", category: "persistence")
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let requestedICloudBackup = userDefaults.bool(forKey: Self.iCloudBackupEnabledKey)
        if requestedICloudBackup && !Self.isICloudBackupCapabilityEnabled {
            Self.logger.info("Disabling requested iCloud backup because the local build lacks the entitlement")
            userDefaults.set(false, forKey: Self.iCloudBackupEnabledKey)
        }

        do {
            self.modelContainer = try Self.makeModelContainer(
                iCloudBackupEnabled: requestedICloudBackup && Self.isICloudBackupCapabilityEnabled
            )
            Self.logger.info("SwiftData model container initialized. iCloud enabled: \(requestedICloudBackup && Self.isICloudBackupCapabilityEnabled, privacy: .public)")
        } catch {
            Self.logger.error("SwiftData model container initialization failed. Falling back to local-only storage")
            userDefaults.set(false, forKey: Self.iCloudBackupEnabledKey)
            do {
                self.modelContainer = try Self.makeModelContainer(iCloudBackupEnabled: false)
                self.startupError = ErrorMessageMapper.map(
                    error,
                    fallback: .loadFailed(context: "iCloud-backed storage"),
                    technicalContext: "SwiftData iCloud container initialization"
                )
            } catch {
                Self.logger.error("SwiftData local-only model container initialization failed. Falling back to in-memory storage")
                do {
                    self.modelContainer = try Self.makeInMemoryModelContainer()
                    self.startupError = PersistenceServiceError.localStoreUnavailable.appError
                } catch {
                    preconditionFailure("Kalirova could not initialize any SwiftData model container.")
                }
            }
        }
    }

    func setICloudBackupEnabled(_ isEnabled: Bool) throws {
        guard !isEnabled || Self.isICloudBackupCapabilityEnabled else {
            userDefaults.set(false, forKey: Self.iCloudBackupEnabledKey)
            throw PersistenceServiceError.iCloudCapabilityUnavailable
        }

        let updatedContainer = try Self.makeModelContainer(iCloudBackupEnabled: isEnabled)
        userDefaults.set(isEnabled, forKey: Self.iCloudBackupEnabledKey)
        modelContainer = updatedContainer
        Self.logger.info("SwiftData storage mode changed. iCloud enabled: \(isEnabled, privacy: .public)")
    }

    static func makeModelContainer(iCloudBackupEnabled: Bool) throws -> ModelContainer {
        let schema = appSchema
        let shouldUseCloudKit = iCloudBackupEnabled && isICloudBackupCapabilityEnabled
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = shouldUseCloudKit
            ? .private(iCloudContainerIdentifier)
            : .none
        let configuration = ModelConfiguration(
            "Kalirova",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDatabase
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = appSchema
        let configuration = ModelConfiguration(
            "Kalirova",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static var appSchema: Schema {
        Schema([
            UserProfile.self,
            DailySummary.self,
            MealEntry.self,
            FoodItem.self,
            WorkoutEntry.self,
            HealthMetricEntry.self,
            Goal.self,
            AISummary.self,
            AppSettings.self
        ])
    }
}
