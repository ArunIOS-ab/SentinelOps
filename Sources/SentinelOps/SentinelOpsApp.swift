import AppShell
import Persistence
import SwiftData
import SwiftUI

@main
struct SentinelOpsApp: App {
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([PersistedIncident.self])
        let configuration = ModelConfiguration("SentinelOps", schema: schema)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to create the required SentinelOps data container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellRoot()
        }
        .modelContainer(modelContainer)
    }
}
