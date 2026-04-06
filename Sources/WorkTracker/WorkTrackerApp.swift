import SwiftUI

@main
struct WorkTrackerApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup("WorkTracker") {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
        .defaultSize(width: 1200, height: 800)
    }
}
