import SwiftData
import SwiftUI

@main
struct KalirovaApp: App {
    @StateObject private var persistenceService = PersistenceService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(persistenceService)
        }
        .modelContainer(persistenceService.modelContainer)
    }
}
