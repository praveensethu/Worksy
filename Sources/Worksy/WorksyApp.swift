import SwiftUI

@main
struct WorksyApp: App {
    let persistence = PersistenceController.shared

    init() {
        AppIconGenerator.setAppIcon()

        // Enable undo manager on the view context
        persistence.container.viewContext.undoManager = UndoManager()

        let context = persistence.container.viewContext
        if DataMigrationService.shouldImport(context: context) {
            DataMigrationService.importFromSublime(context: context)
        }
        DataMigrationService.reimportNotesIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup("Worksy") {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Board from Template...") {
                    NotificationCenter.default.post(name: .showTemplates, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
            // Undo/Redo is automatically handled by Core Data's undo manager
        }
    }
}

extension Notification.Name {
    static let showTemplates = Notification.Name("showTemplates")
}
