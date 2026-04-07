import CoreData

@objc(Card)
public class Card: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var cardDescription: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var column: BoardColumn?

    convenience init(context: NSManagedObjectContext, title: String, column: BoardColumn? = nil) {
        let entity = NSEntityDescription.entity(forEntityName: "Card", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.title = title
        self.sortOrder = 0
        self.createdAt = Date()
        self.column = column
    }
}
