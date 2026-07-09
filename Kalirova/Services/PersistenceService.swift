import Foundation
import SwiftData
import SwiftUI

enum PersistenceServiceError: LocalizedError {
    case iCloudCapabilityUnavailable

    var errorDescription: String? {
        switch self {
        case .iCloudCapabilityUnavailable:
            "iCloud Backup is disabled for this local development build. Re-enable the iCloud capability and ENABLE_ICLOUD_BACKUP build flag with a paid Apple Developer account."
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

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let requestedICloudBackup = userDefaults.bool(forKey: Self.iCloudBackupEnabledKey)
        if requestedICloudBackup && !Self.isICloudBackupCapabilityEnabled {
            userDefaults.set(false, forKey: Self.iCloudBackupEnabledKey)
        }

        do {
            self.modelContainer = try Self.makeModelContainer(
                iCloudBackupEnabled: requestedICloudBackup && Self.isICloudBackupCapabilityEnabled
            )
        } catch {
            userDefaults.set(false, forKey: Self.iCloudBackupEnabledKey)
            self.modelContainer = try! Self.makeModelContainer(iCloudBackupEnabled: false)
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
