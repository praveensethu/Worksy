import CoreData

final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Migrate from old "WorkTracker" directory if needed
        PersistenceController.migrateFromOldLocation()

        let model = CoreDataModel.createModel()
        container = NSPersistentContainer(name: "Worksy", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            let storeURL = PersistenceController.storeURL()
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load Core Data store: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
        }
    }

    private static func storeURL() -> URL {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = appSupportURL.appendingPathComponent("Worksy", isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                fatalError("Failed to create Application Support directory: \(error)")
            }
        }

        return directoryURL.appendingPathComponent("Worksy.sqlite")
    }

    /// Migrate database from old "WorkTracker" location to new "Worksy" location.
    /// Copies all SQLite files (main, -wal, -shm) so existing data is preserved.
    private static func migrateFromOldLocation() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        let oldDir = appSupportURL.appendingPathComponent("WorkTracker", isDirectory: true)
        let newDir = appSupportURL.appendingPathComponent("Worksy", isDirectory: true)

        let oldDB = oldDir.appendingPathComponent("WorkTracker.sqlite")
        let newDB = newDir.appendingPathComponent("Worksy.sqlite")

        // Only migrate if old DB exists and new DB does not
        guard fileManager.fileExists(atPath: oldDB.path),
              !fileManager.fileExists(atPath: newDB.path) else { return }

        do {
            // Create new directory if needed
            if !fileManager.fileExists(atPath: newDir.path) {
                try fileManager.createDirectory(at: newDir, withIntermediateDirectories: true)
            }

            // Copy all SQLite-related files
            let suffixes = ["", "-wal", "-shm"]
            for suffix in suffixes {
                let oldFile = oldDir.appendingPathComponent("WorkTracker.sqlite\(suffix)")
                let newFile = newDir.appendingPathComponent("Worksy.sqlite\(suffix)")
                if fileManager.fileExists(atPath: oldFile.path) {
                    try fileManager.copyItem(at: oldFile, to: newFile)
                }
            }

            // Also copy Backgrounds directory if it exists
            let oldBG = oldDir.appendingPathComponent("Backgrounds")
            let newBG = newDir.appendingPathComponent("Backgrounds")
            if fileManager.fileExists(atPath: oldBG.path), !fileManager.fileExists(atPath: newBG.path) {
                try fileManager.copyItem(at: oldBG, to: newBG)
            }

            print("[PersistenceController] Successfully migrated data from WorkTracker to Worksy.")
        } catch {
            print("[PersistenceController] Migration from WorkTracker failed: \(error). Will start fresh.")
        }
    }
}
