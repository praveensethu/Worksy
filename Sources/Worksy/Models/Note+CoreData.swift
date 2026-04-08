import CoreData

@objc(Note)
public class Note: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isPlainText: Bool
    @NSManaged public var folder: Folder?

    convenience init(context: NSManagedObjectContext, title: String, folder: Folder? = nil) {
        let entity = NSEntityDescription.entity(forEntityName: "Note", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.folder = folder
    }
}
