import Foundation
import SwiftUI

@MainActor
final class ICloudBackupService: ObservableObject {
    @Published private(set) var availabilityText = "Checking iCloud status..."

    private let userDefaults: UserDefaults
    private let lastBackupKey = "LastICloudBackupAt"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        refreshAvailability()
    }

    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var lastBackupAt: Date? {
        get { userDefaults.object(forKey: lastBackupKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastBackupKey) }
    }

    func refreshAvailability() {
        availabilityText = isAvailable
            ? "iCloud account available"
            : "No iCloud account is available on this device"
    }

    func recordSuccessfulBackup() {
        lastBackupAt = .now
    }

    func formattedLastBackup() -> String {
        guard let lastBackupAt else {
            return "No successful iCloud backup yet"
        }

        return lastBackupAt.formatted(date: .abbreviated, time: .shortened)
    }
}
