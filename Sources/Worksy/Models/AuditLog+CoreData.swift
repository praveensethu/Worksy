import CoreData

@objc(AuditLog)
public class AuditLog: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var entityType: String?
    @NSManaged public var entityId: UUID?
    @NSManaged public var action: String?
    @NSManaged public var details: String?

    convenience init(
        context: NSManagedObjectContext,
        entityType: String,
        entityId: UUID,
        action: String,
        details: String = "{}"
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "AuditLog", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.timestamp = Date()
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.details = details
    }
}
