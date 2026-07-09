import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PersistenceService: ObservableObject {
    static let iCloudBackupEnabledKey = "iCloudBackupEnabled"
    static let iCloudContainerIdentifier = "iCloud.com.kalirova.app"

    @Published private(set) var modelContainer: ModelContainer

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        do {
            self.modelContainer = try Self.makeModelContainer(
                iCloudBackupEnabled: userDefaults.bool(forKey: Self.iCloudBackupEnabledKey)
            )
        } catch {
            userDefaults.set(false, forKey: Self.iCloudBackupEnabledKey)
            self.modelContainer = try! Self.makeModelContainer(iCloudBackupEnabled: false)
        }
    }

    func setICloudBackupEnabled(_ isEnabled: Bool) throws {
        let updatedContainer = try Self.makeModelContainer(iCloudBackupEnabled: isEnabled)
        userDefaults.set(isEnabled, forKey: Self.iCloudBackupEnabledKey)
        modelContainer = updatedContainer
    }

    static func makeModelContainer(iCloudBackupEnabled: Bool) throws -> ModelContainer {
        let schema = appSchema
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = iCloudBackupEnabled
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
