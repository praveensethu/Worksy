import SwiftUI

@main
struct WorkTrackerApp: App {
    let persistence = PersistenceController.shared

    init() {
        AppIconGenerator.setAppIcon()

        let context = persistence.container.viewContext
        if DataMigrationService.shouldImport(context: context) {
            DataMigrationService.importFromSublime(context: context)
        }
    }

    var body: some Scene {
        WindowGroup("WorkTracker") {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
