import CoreData

@objc(Card)
public class Card: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var cardDescription: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var isArchived: Bool
    @NSManaged public var isPinned: Bool
    @NSManaged public var labels: String?
    @NSManaged public var column: BoardColumn?

    convenience init(context: NSManagedObjectContext, title: String, column: BoardColumn? = nil) {
        let entity = NSEntityDescription.entity(forEntityName: "Card", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.title = title
        self.sortOrder = 0
        self.createdAt = Date()
        self.isArchived = false
        self.isPinned = false
        self.column = column
    }

    var labelArray: [String] {
        get { labels?.split(separator: ",").map(String.init) ?? [] }
        set { labels = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && !isArchived
    }
}
