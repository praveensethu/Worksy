import CoreData

@objc(Folder)
public class Folder: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var parent: Folder?
    @NSManaged public var children: NSSet?
    @NSManaged public var notes: NSSet?

    convenience init(context: NSManagedObjectContext, name: String, parent: Folder? = nil) {
        let entity = NSEntityDescription.entity(forEntityName: "Folder", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.name = name
        self.sortOrder = 0
        self.parent = parent
    }
}

// MARK: - Generated accessors for children
extension Folder {
    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: Folder)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: Folder)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)
}

// MARK: - Generated accessors for notes
extension Folder {
    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: Note)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: Note)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)
}
