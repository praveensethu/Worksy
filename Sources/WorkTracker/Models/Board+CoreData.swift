import CoreData

@objc(Board)
public class Board: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var backgroundImage: String?
    @NSManaged public var columns: NSSet?

    convenience init(context: NSManagedObjectContext, name: String, color: String = "#007AFF") {
        let entity = NSEntityDescription.entity(forEntityName: "Board", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.name = name
        self.color = color
        self.sortOrder = 0
        self.createdAt = Date()
    }
}

// MARK: - Generated accessors for columns
extension Board {
    @objc(addColumnsObject:)
    @NSManaged public func addToColumns(_ value: BoardColumn)

    @objc(removeColumnsObject:)
    @NSManaged public func removeFromColumns(_ value: BoardColumn)

    @objc(addColumns:)
    @NSManaged public func addToColumns(_ values: NSSet)

    @objc(removeColumns:)
    @NSManaged public func removeFromColumns(_ values: NSSet)
}
