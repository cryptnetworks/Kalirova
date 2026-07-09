import Foundation
import SwiftUI

@MainActor
final class ICloudBackupService: ObservableObject {
    @Published private(set) var availabilityText = "iCloud Backup is disabled for this local development build"

    private let userDefaults: UserDefaults
    private let lastBackupKey = "LastICloudBackupAt"
    private static let disabledAvailabilityText = "iCloud Backup is disabled for this local development build"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        refreshAvailability()
    }

    var isAvailable: Bool {
        guard PersistenceService.isICloudBackupCapabilityEnabled else { return false }
        return FileManager.default.ubiquityIdentityToken != nil
    }

    var lastBackupAt: Date? {
        get { userDefaults.object(forKey: lastBackupKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastBackupKey) }
    }

    func refreshAvailability() {
        guard PersistenceService.isICloudBackupCapabilityEnabled else {
            availabilityText = Self.disabledAvailabilityText
            return
        }

        availabilityText = isAvailable
            ? "iCloud account available"
            : "No iCloud account is available on this device"
    }

    func recordSuccessfulBackup() {
        guard PersistenceService.isICloudBackupCapabilityEnabled else { return }
        lastBackupAt = .now
    }

    func formattedLastBackup() -> String {
        guard let lastBackupAt else {
            return "No successful iCloud backup yet"
        }

        return lastBackupAt.formatted(date: .abbreviated, time: .shortened)
    }
}
