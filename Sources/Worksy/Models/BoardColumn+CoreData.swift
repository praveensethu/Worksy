import CoreData

@objc(BoardColumn)
public class BoardColumn: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var wipLimit: Int16
    @NSManaged public var board: Board?
    @NSManaged public var cards: NSSet?

    convenience init(context: NSManagedObjectContext, name: String, board: Board? = nil) {
        let entity = NSEntityDescription.entity(forEntityName: "BoardColumn", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.name = name
        self.sortOrder = 0
        self.wipLimit = 0
        self.board = board
    }

    var activeCards: [Card] {
        (cards?.allObjects as? [Card] ?? []).filter { !$0.isArchived }
    }

    var isOverWipLimit: Bool {
        wipLimit > 0 && activeCards.count > Int(wipLimit)
    }
}

// MARK: - Generated accessors for cards
extension BoardColumn {
    @objc(addCardsObject:)
    @NSManaged public func addToCards(_ value: Card)

    @objc(removeCardsObject:)
    @NSManaged public func removeFromCards(_ value: Card)

    @objc(addCards:)
    @NSManaged public func addToCards(_ values: NSSet)

    @objc(removeCards:)
    @NSManaged public func removeFromCards(_ values: NSSet)
}
