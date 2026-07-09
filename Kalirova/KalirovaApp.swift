import OSLog
import SwiftData
import SwiftUI

@main
struct KalirovaApp: App {
    @StateObject private var persistenceService = PersistenceService()
    private static let logger = Logger(subsystem: "com.kalirova.app", category: "lifecycle")

    init() {
        Self.logger.info("Kalirova app initialized")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(persistenceService)
        }
        .modelContainer(persistenceService.modelContainer)
    }
}
