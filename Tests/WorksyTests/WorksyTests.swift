import XCTest
import CoreData
@testable import Worksy

final class WorksyTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        let controller = PersistenceController(inMemory: true)
        context = controller.container.viewContext
    }

    override func tearDownWithError() throws {
        context = nil
    }

    // MARK: - Board CRUD

    func testCreateBoard() throws {
        let board = Board(context: context, name: "Test Board", color: "#FF6B6B")
        try context.save()

        XCTAssertNotNil(board.id)
        XCTAssertEqual(board.name, "Test Board")
        XCTAssertEqual(board.color, "#FF6B6B")
        XCTAssertEqual(board.sortOrder, 0)
        XCTAssertNotNil(board.createdAt)
    }

    func testCreateBoardWithDefaultColor() throws {
        let board = Board(context: context, name: "Default Color Board")
        try context.save()

        XCTAssertEqual(board.color, "#FFB800")
    }

    func testRenameBoard() throws {
        let board = Board(context: context, name: "Old Name")
        try context.save()

        board.name = "New Name"
        try context.save()

        XCTAssertEqual(board.name, "New Name")
    }

    func testDeleteBoard() throws {
        let board = Board(context: context, name: "To Delete")
        try context.save()

        context.delete(board)
        try context.save()

        let request = NSFetchRequest<Board>(entityName: "Board")
        let boards = try context.fetch(request)
        XCTAssertTrue(boards.isEmpty)
    }

    func testDeleteBoardCascadesColumns() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Column", board: board)
        _ = col
        try context.save()

        context.delete(board)
        try context.save()

        let colRequest = NSFetchRequest<BoardColumn>(entityName: "BoardColumn")
        let columns = try context.fetch(colRequest)
        XCTAssertTrue(columns.isEmpty, "Columns should be cascade deleted with board")
    }

    func testDeleteBoardCascadesColumnsAndCards() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Column", board: board)
        let card = Card(context: context, title: "Card", column: col)
        _ = card
        try context.save()

        context.delete(board)
        try context.save()

        let cardRequest = NSFetchRequest<Card>(entityName: "Card")
        let cards = try context.fetch(cardRequest)
        XCTAssertTrue(cards.isEmpty, "Cards should be cascade deleted with board")
    }

    // MARK: - BoardColumn CRUD

    func testCreateColumn() throws {
        let board = Board(context: context, name: "Board")
        let column = BoardColumn(context: context, name: "To Do", board: board)
        try context.save()

        XCTAssertNotNil(column.id)
        XCTAssertEqual(column.name, "To Do")
        XCTAssertEqual(column.sortOrder, 0)
        XCTAssertEqual(column.wipLimit, 0)
        XCTAssertEqual(column.board?.id, board.id)
    }

    func testRenameColumn() throws {
        let board = Board(context: context, name: "Board")
        let column = BoardColumn(context: context, name: "Old", board: board)
        try context.save()

        column.name = "New"
        try context.save()

        XCTAssertEqual(column.name, "New")
    }

    func testDeleteColumn() throws {
        let board = Board(context: context, name: "Board")
        let column = BoardColumn(context: context, name: "To Delete", board: board)
        _ = column
        try context.save()

        context.delete(column)
        try context.save()

        let columns = (board.columns?.allObjects as? [BoardColumn]) ?? []
        XCTAssertTrue(columns.isEmpty)
    }

    func testDeleteColumnCascadesCards() throws {
        let board = Board(context: context, name: "Board")
        let column = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: column)
        _ = card
        try context.save()

        context.delete(column)
        try context.save()

        let cardRequest = NSFetchRequest<Card>(entityName: "Card")
        let cards = try context.fetch(cardRequest)
        XCTAssertTrue(cards.isEmpty, "Cards should be cascade deleted with column")
    }

    func testSetWipLimit() throws {
        let board = Board(context: context, name: "Board")
        let column = BoardColumn(context: context, name: "Col", board: board)
        column.wipLimit = 3
        try context.save()

        XCTAssertEqual(column.wipLimit, 3)
    }

    // MARK: - Column Reordering (Move Left / Move Right)

    func testMoveColumnRight() throws {
        let board = Board(context: context, name: "Board")
        let col1 = BoardColumn(context: context, name: "To Do", board: board)
        col1.sortOrder = 0
        let col2 = BoardColumn(context: context, name: "In Progress", board: board)
        col2.sortOrder = 1
        let col3 = BoardColumn(context: context, name: "Done", board: board)
        col3.sortOrder = 2
        try context.save()

        // Move col1 right (swap with col2)
        var columns = (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
        let currentIndex = columns.firstIndex(where: { $0.id == col1.id })!
        let newIndex = currentIndex + 1
        columns.swapAt(currentIndex, newIndex)
        for (i, col) in columns.enumerated() { col.sortOrder = Int16(i) }
        try context.save()

        XCTAssertEqual(col1.sortOrder, 1)
        XCTAssertEqual(col2.sortOrder, 0)
        XCTAssertEqual(col3.sortOrder, 2)
    }

    func testMoveColumnLeft() throws {
        let board = Board(context: context, name: "Board")
        let col1 = BoardColumn(context: context, name: "To Do", board: board)
        col1.sortOrder = 0
        let col2 = BoardColumn(context: context, name: "In Progress", board: board)
        col2.sortOrder = 1
        let col3 = BoardColumn(context: context, name: "Done", board: board)
        col3.sortOrder = 2
        try context.save()

        // Move col3 left (swap with col2)
        var columns = (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
        let currentIndex = columns.firstIndex(where: { $0.id == col3.id })!
        let newIndex = currentIndex - 1
        columns.swapAt(currentIndex, newIndex)
        for (i, col) in columns.enumerated() { col.sortOrder = Int16(i) }
        try context.save()

        XCTAssertEqual(col1.sortOrder, 0)
        XCTAssertEqual(col2.sortOrder, 2)
        XCTAssertEqual(col3.sortOrder, 1)
    }

    func testMoveLeftmostColumnLeftIsNoop() throws {
        let board = Board(context: context, name: "Board")
        let col1 = BoardColumn(context: context, name: "First", board: board)
        col1.sortOrder = 0
        let col2 = BoardColumn(context: context, name: "Second", board: board)
        col2.sortOrder = 1
        try context.save()

        // Attempt to move col1 left — should be rejected
        let columns = (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
        let currentIndex = columns.firstIndex(where: { $0.id == col1.id })!
        let newIndex = currentIndex - 1

        XCTAssertTrue(newIndex < 0, "Cannot move leftmost column further left")
        // sortOrders should be unchanged
        XCTAssertEqual(col1.sortOrder, 0)
        XCTAssertEqual(col2.sortOrder, 1)
    }

    func testMoveRightmostColumnRightIsNoop() throws {
        let board = Board(context: context, name: "Board")
        let col1 = BoardColumn(context: context, name: "First", board: board)
        col1.sortOrder = 0
        let col2 = BoardColumn(context: context, name: "Second", board: board)
        col2.sortOrder = 1
        try context.save()

        let columns = (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
        let currentIndex = columns.firstIndex(where: { $0.id == col2.id })!
        let newIndex = currentIndex + 1

        XCTAssertTrue(newIndex >= columns.count, "Cannot move rightmost column further right")
        XCTAssertEqual(col1.sortOrder, 0)
        XCTAssertEqual(col2.sortOrder, 1)
    }

    // MARK: - Card CRUD

    func testCreateCard() throws {
        let board = Board(context: context, name: "Board")
        let column = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "My Card", column: column)
        try context.save()

        XCTAssertNotNil(card.id)
        XCTAssertEqual(card.title, "My Card")
        XCTAssertEqual(card.sortOrder, 0)
        XCTAssertFalse(card.isArchived)
        XCTAssertFalse(card.isPinned)
        XCTAssertNotNil(card.createdAt)
        XCTAssertEqual(card.column?.id, column.id)
    }

    func testRenameCard() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Old Title", column: col)
        try context.save()

        card.title = "New Title"
        try context.save()

        XCTAssertEqual(card.title, "New Title")
    }

    func testDeleteCard() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "To Delete", column: col)
        _ = card
        try context.save()

        context.delete(card)
        try context.save()

        let request = NSFetchRequest<Card>(entityName: "Card")
        let cards = try context.fetch(request)
        XCTAssertTrue(cards.isEmpty)
    }

    // MARK: - Mark as Done (Delete Card)

    func testMarkAsDoneDeletesCard() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Done Task", column: col)
        let cardId = card.id!
        try context.save()

        // Simulate "Mark as Done" — logs and deletes
        AuditService.shared.logDelete(
            entityType: "Card", entityId: cardId,
            details: ["title": "Done Task", "column": "Col", "reason": "marked_done"],
            context: context
        )
        context.delete(card)
        try context.save()

        let cardRequest = NSFetchRequest<Card>(entityName: "Card")
        let cards = try context.fetch(cardRequest)
        XCTAssertTrue(cards.isEmpty, "Card should be deleted after Mark as Done")

        // Verify audit log was created
        let logs = AuditService.shared.history(for: cardId, context: context)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.action, "deleted")
        XCTAssertTrue(logs.first?.details?.contains("marked_done") ?? false)
    }

    func testMarkAsDoneDoesNotAffectOtherCards() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card1 = Card(context: context, title: "Keep This", column: col)
        let card2 = Card(context: context, title: "Done", column: col)
        _ = card1
        try context.save()

        context.delete(card2)
        try context.save()

        let request = NSFetchRequest<Card>(entityName: "Card")
        let cards = try context.fetch(request)
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.title, "Keep This")
    }

    // MARK: - Card Labels

    func testCardLabels() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)

        card.labelArray = ["urgent", "bug"]
        XCTAssertEqual(card.labels, "urgent,bug")
        XCTAssertEqual(card.labelArray, ["urgent", "bug"])
    }

    func testCardLabelsEmpty() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)

        XCTAssertTrue(card.labelArray.isEmpty)

        card.labelArray = []
        XCTAssertNil(card.labels)
    }

    // MARK: - Card Pin

    func testTogglePin() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)
        try context.save()

        XCTAssertFalse(card.isPinned)

        card.isPinned = true
        try context.save()
        XCTAssertTrue(card.isPinned)

        card.isPinned = false
        try context.save()
        XCTAssertFalse(card.isPinned)
    }

    // MARK: - Card Archive

    func testArchiveCard() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)
        try context.save()

        XCTAssertFalse(card.isArchived)

        card.isArchived = true
        try context.save()
        XCTAssertTrue(card.isArchived)
    }

    func testActiveCardsExcludesArchived() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card1 = Card(context: context, title: "Active", column: col)
        let card2 = Card(context: context, title: "Archived", column: col)
        card2.isArchived = true
        _ = card1
        try context.save()

        let activeCards = col.activeCards
        XCTAssertEqual(activeCards.count, 1)
        XCTAssertEqual(activeCards.first?.title, "Active")
    }

    // MARK: - Card Due Date & Overdue

    func testCardOverdue() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)

        // Due date in the past
        card.dueDate = Date().addingTimeInterval(-86400)
        XCTAssertTrue(card.isOverdue)
    }

    func testCardNotOverdueWhenFuture() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)

        card.dueDate = Date().addingTimeInterval(86400)
        XCTAssertFalse(card.isOverdue)
    }

    func testCardNotOverdueWhenNoDueDate() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)

        XCTAssertNil(card.dueDate)
        XCTAssertFalse(card.isOverdue)
    }

    func testArchivedCardNotOverdue() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)

        card.dueDate = Date().addingTimeInterval(-86400)
        card.isArchived = true
        XCTAssertFalse(card.isOverdue, "Archived cards should not be reported as overdue")
    }

    // MARK: - Card Move Between Columns

    func testMoveCardBetweenColumns() throws {
        let board = Board(context: context, name: "Board")
        let col1 = BoardColumn(context: context, name: "To Do", board: board)
        let col2 = BoardColumn(context: context, name: "Done", board: board)
        let card = Card(context: context, title: "Card", column: col1)
        try context.save()

        XCTAssertEqual(card.column?.id, col1.id)

        card.column = col2
        try context.save()

        XCTAssertEqual(card.column?.id, col2.id)
        XCTAssertEqual(col1.activeCards.count, 0)
        XCTAssertEqual(col2.activeCards.count, 1)
    }

    // MARK: - WIP Limit

    func testWipLimitNotExceeded() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        col.wipLimit = 3
        _ = Card(context: context, title: "Card 1", column: col)
        _ = Card(context: context, title: "Card 2", column: col)
        try context.save()

        XCTAssertFalse(col.isOverWipLimit)
    }

    func testWipLimitExceeded() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        col.wipLimit = 2
        _ = Card(context: context, title: "Card 1", column: col)
        _ = Card(context: context, title: "Card 2", column: col)
        _ = Card(context: context, title: "Card 3", column: col)
        try context.save()

        XCTAssertTrue(col.isOverWipLimit)
    }

    func testWipLimitZeroMeansNoLimit() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        col.wipLimit = 0
        for i in 1...10 {
            _ = Card(context: context, title: "Card \(i)", column: col)
        }
        try context.save()

        XCTAssertFalse(col.isOverWipLimit)
    }

    func testWipLimitIgnoresArchivedCards() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        col.wipLimit = 2
        _ = Card(context: context, title: "Active 1", column: col)
        _ = Card(context: context, title: "Active 2", column: col)
        let archived = Card(context: context, title: "Archived", column: col)
        archived.isArchived = true
        try context.save()

        XCTAssertFalse(col.isOverWipLimit, "Archived cards should not count toward WIP limit")
    }

    // MARK: - Folder CRUD

    func testCreateFolder() throws {
        let folder = Folder(context: context, name: "My Folder")
        try context.save()

        XCTAssertNotNil(folder.id)
        XCTAssertEqual(folder.name, "My Folder")
        XCTAssertNil(folder.parent)
    }

    func testCreateSubfolder() throws {
        let parent = Folder(context: context, name: "Parent")
        let child = Folder(context: context, name: "Child", parent: parent)
        try context.save()

        XCTAssertEqual(child.parent?.id, parent.id)
        let children = parent.children?.allObjects as? [Folder] ?? []
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.first?.name, "Child")
    }

    func testDeleteFolderCascadesChildren() throws {
        let parent = Folder(context: context, name: "Parent")
        let child = Folder(context: context, name: "Child", parent: parent)
        _ = child
        try context.save()

        context.delete(parent)
        try context.save()

        let request = NSFetchRequest<Folder>(entityName: "Folder")
        let folders = try context.fetch(request)
        XCTAssertTrue(folders.isEmpty, "Child folders should be cascade deleted")
    }

    func testDeleteFolderCascadesNotes() throws {
        let folder = Folder(context: context, name: "Folder")
        let note = Note(context: context, title: "Note", folder: folder)
        _ = note
        try context.save()

        context.delete(folder)
        try context.save()

        let request = NSFetchRequest<Note>(entityName: "Note")
        let notes = try context.fetch(request)
        XCTAssertTrue(notes.isEmpty, "Notes should be cascade deleted with folder")
    }

    // MARK: - Note CRUD

    func testCreateNote() throws {
        let folder = Folder(context: context, name: "Folder")
        let note = Note(context: context, title: "My Note", folder: folder)
        try context.save()

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, "My Note")
        XCTAssertNotNil(note.createdAt)
        XCTAssertNotNil(note.updatedAt)
        XCTAssertEqual(note.folder?.id, folder.id)
    }

    func testRenameNote() throws {
        let folder = Folder(context: context, name: "Folder")
        let note = Note(context: context, title: "Old", folder: folder)
        try context.save()

        note.title = "New"
        note.updatedAt = Date()
        try context.save()

        XCTAssertEqual(note.title, "New")
    }

    func testDeleteNote() throws {
        let folder = Folder(context: context, name: "Folder")
        let note = Note(context: context, title: "To Delete", folder: folder)
        _ = note
        try context.save()

        context.delete(note)
        try context.save()

        let request = NSFetchRequest<Note>(entityName: "Note")
        let notes = try context.fetch(request)
        XCTAssertTrue(notes.isEmpty)
    }

    // MARK: - AuditService

    func testAuditLogCreate() throws {
        let entityId = UUID()
        AuditService.shared.logCreate(
            entityType: "Card", entityId: entityId,
            details: ["title": "Test"], context: context
        )
        try context.save()

        let logs = AuditService.shared.history(for: entityId, context: context)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.action, "created")
        XCTAssertEqual(logs.first?.entityType, "Card")
    }

    func testAuditLogUpdate() throws {
        let entityId = UUID()
        AuditService.shared.logUpdate(
            entityType: "Card", entityId: entityId,
            field: "title", oldValue: "Old", newValue: "New", context: context
        )
        try context.save()

        let logs = AuditService.shared.history(for: entityId, context: context)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.action, "updated")
        XCTAssertTrue(logs.first?.details?.contains("title") ?? false)
    }

    func testAuditLogMove() throws {
        let entityId = UUID()
        AuditService.shared.logMove(
            entityType: "Card", entityId: entityId,
            fromColumn: "To Do", toColumn: "Done", context: context
        )
        try context.save()

        let logs = AuditService.shared.history(for: entityId, context: context)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.action, "moved")
        XCTAssertTrue(logs.first?.details?.contains("To Do") ?? false)
        XCTAssertTrue(logs.first?.details?.contains("Done") ?? false)
    }

    func testAuditLogDelete() throws {
        let entityId = UUID()
        AuditService.shared.logDelete(
            entityType: "Card", entityId: entityId,
            details: ["title": "Deleted Card"], context: context
        )
        try context.save()

        let logs = AuditService.shared.history(for: entityId, context: context)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.action, "deleted")
    }

    func testAuditHistoryOrderedByTimestamp() throws {
        let entityId = UUID()
        AuditService.shared.logCreate(
            entityType: "Card", entityId: entityId,
            details: ["title": "Card"], context: context
        )
        AuditService.shared.logUpdate(
            entityType: "Card", entityId: entityId,
            field: "title", oldValue: "Card", newValue: "Updated", context: context
        )
        AuditService.shared.logDelete(
            entityType: "Card", entityId: entityId,
            details: ["title": "Updated"], context: context
        )
        try context.save()

        let logs = AuditService.shared.history(for: entityId, context: context)
        XCTAssertEqual(logs.count, 3)
        // Most recent first
        XCTAssertEqual(logs[0].action, "deleted")
    }

    func testAuditHistoryIsolatedPerEntity() throws {
        let id1 = UUID()
        let id2 = UUID()
        AuditService.shared.logCreate(
            entityType: "Card", entityId: id1,
            details: ["title": "Card 1"], context: context
        )
        AuditService.shared.logCreate(
            entityType: "Card", entityId: id2,
            details: ["title": "Card 2"], context: context
        )
        try context.save()

        let logs1 = AuditService.shared.history(for: id1, context: context)
        let logs2 = AuditService.shared.history(for: id2, context: context)
        XCTAssertEqual(logs1.count, 1)
        XCTAssertEqual(logs2.count, 1)
    }

    // MARK: - Multiple Boards Isolation

    func testMultipleBoardsAreIndependent() throws {
        let board1 = Board(context: context, name: "Board 1")
        let board2 = Board(context: context, name: "Board 2")
        _ = BoardColumn(context: context, name: "Col A", board: board1)
        _ = BoardColumn(context: context, name: "Col B", board: board1)
        _ = BoardColumn(context: context, name: "Col C", board: board2)
        try context.save()

        let cols1 = board1.columns?.allObjects as? [BoardColumn] ?? []
        let cols2 = board2.columns?.allObjects as? [BoardColumn] ?? []
        XCTAssertEqual(cols1.count, 2)
        XCTAssertEqual(cols2.count, 1)
    }

    // MARK: - Board Sort Order

    func testBoardSortOrder() throws {
        let board1 = Board(context: context, name: "First")
        board1.sortOrder = 0
        let board2 = Board(context: context, name: "Second")
        board2.sortOrder = 1
        let board3 = Board(context: context, name: "Third")
        board3.sortOrder = 2
        try context.save()

        let request = NSFetchRequest<Board>(entityName: "Board")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        let boards = try context.fetch(request)

        XCTAssertEqual(boards[0].name, "First")
        XCTAssertEqual(boards[1].name, "Second")
        XCTAssertEqual(boards[2].name, "Third")
    }

    // MARK: - Card Sort Order Within Column

    func testCardSortOrderWithinColumn() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card1 = Card(context: context, title: "First", column: col)
        card1.sortOrder = 0
        let card2 = Card(context: context, title: "Second", column: col)
        card2.sortOrder = 1
        let card3 = Card(context: context, title: "Third", column: col)
        card3.sortOrder = 2
        try context.save()

        let sorted = col.activeCards.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted[0].title, "First")
        XCTAssertEqual(sorted[1].title, "Second")
        XCTAssertEqual(sorted[2].title, "Third")
    }

    // MARK: - Pinned Cards Sort Before Unpinned

    func testPinnedCardsSortFirst() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card1 = Card(context: context, title: "Unpinned", column: col)
        card1.sortOrder = 0
        let card2 = Card(context: context, title: "Pinned", column: col)
        card2.sortOrder = 1
        card2.isPinned = true
        try context.save()

        let sorted = col.activeCards.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.sortOrder < $1.sortOrder
        }
        XCTAssertEqual(sorted[0].title, "Pinned")
        XCTAssertEqual(sorted[1].title, "Unpinned")
    }

    // MARK: - PersistenceController

    func testInMemoryStoreHasNoData() throws {
        let request = NSFetchRequest<Board>(entityName: "Board")
        let boards = try context.fetch(request)
        XCTAssertTrue(boards.isEmpty)
    }

    func testInMemoryStoreCanSaveAndFetch() throws {
        _ = Board(context: context, name: "Test")
        try context.save()

        let request = NSFetchRequest<Board>(entityName: "Board")
        let boards = try context.fetch(request)
        XCTAssertEqual(boards.count, 1)
    }

    // MARK: - Card Description

    func testCardDescription() throws {
        let board = Board(context: context, name: "Board")
        let col = BoardColumn(context: context, name: "Col", board: board)
        let card = Card(context: context, title: "Card", column: col)
        card.cardDescription = "Some description\nWith multiple lines"
        try context.save()

        XCTAssertEqual(card.cardDescription, "Some description\nWith multiple lines")
    }

    // MARK: - Background Image

    func testBoardBackgroundImage() throws {
        let board = Board(context: context, name: "Board")
        XCTAssertNil(board.backgroundImage)

        board.backgroundImage = "mountain.jpg"
        try context.save()

        XCTAssertEqual(board.backgroundImage, "mountain.jpg")
    }
}
