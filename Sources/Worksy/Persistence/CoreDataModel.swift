import CoreData

enum CoreDataModel {

    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: - Entity Descriptions

        let boardEntity = NSEntityDescription()
        boardEntity.name = "Board"
        boardEntity.managedObjectClassName = "Board"

        let boardColumnEntity = NSEntityDescription()
        boardColumnEntity.name = "BoardColumn"
        boardColumnEntity.managedObjectClassName = "BoardColumn"

        let cardEntity = NSEntityDescription()
        cardEntity.name = "Card"
        cardEntity.managedObjectClassName = "Card"

        let folderEntity = NSEntityDescription()
        folderEntity.name = "Folder"
        folderEntity.managedObjectClassName = "Folder"

        let noteEntity = NSEntityDescription()
        noteEntity.name = "Note"
        noteEntity.managedObjectClassName = "Note"

        let auditLogEntity = NSEntityDescription()
        auditLogEntity.name = "AuditLog"
        auditLogEntity.managedObjectClassName = "AuditLog"

        // MARK: - Board Attributes

        let boardId = NSAttributeDescription()
        boardId.name = "id"
        boardId.attributeType = .UUIDAttributeType

        let boardName = NSAttributeDescription()
        boardName.name = "name"
        boardName.attributeType = .stringAttributeType
        boardName.defaultValue = ""

        let boardColor = NSAttributeDescription()
        boardColor.name = "color"
        boardColor.attributeType = .stringAttributeType
        boardColor.defaultValue = "#FFB800"

        let boardSortOrder = NSAttributeDescription()
        boardSortOrder.name = "sortOrder"
        boardSortOrder.attributeType = .integer16AttributeType
        boardSortOrder.defaultValue = Int16(0)

        let boardCreatedAt = NSAttributeDescription()
        boardCreatedAt.name = "createdAt"
        boardCreatedAt.attributeType = .dateAttributeType

        let boardBackgroundImage = NSAttributeDescription()
        boardBackgroundImage.name = "backgroundImage"
        boardBackgroundImage.attributeType = .stringAttributeType
        boardBackgroundImage.isOptional = true

        boardEntity.properties = [boardId, boardName, boardColor, boardSortOrder, boardCreatedAt, boardBackgroundImage]

        // MARK: - BoardColumn Attributes

        let columnId = NSAttributeDescription()
        columnId.name = "id"
        columnId.attributeType = .UUIDAttributeType

        let columnName = NSAttributeDescription()
        columnName.name = "name"
        columnName.attributeType = .stringAttributeType
        columnName.defaultValue = ""

        let columnSortOrder = NSAttributeDescription()
        columnSortOrder.name = "sortOrder"
        columnSortOrder.attributeType = .integer16AttributeType
        columnSortOrder.defaultValue = Int16(0)

        let columnWipLimit = NSAttributeDescription()
        columnWipLimit.name = "wipLimit"
        columnWipLimit.attributeType = .integer16AttributeType
        columnWipLimit.defaultValue = Int16(0)  // 0 means no limit

        boardColumnEntity.properties = [columnId, columnName, columnSortOrder, columnWipLimit]

        // MARK: - Card Attributes

        let cardId = NSAttributeDescription()
        cardId.name = "id"
        cardId.attributeType = .UUIDAttributeType

        let cardTitle = NSAttributeDescription()
        cardTitle.name = "title"
        cardTitle.attributeType = .stringAttributeType
        cardTitle.defaultValue = ""

        let cardDescription = NSAttributeDescription()
        cardDescription.name = "cardDescription"
        cardDescription.attributeType = .stringAttributeType
        cardDescription.isOptional = true

        let cardSortOrder = NSAttributeDescription()
        cardSortOrder.name = "sortOrder"
        cardSortOrder.attributeType = .integer16AttributeType
        cardSortOrder.defaultValue = Int16(0)

        let cardCreatedAt = NSAttributeDescription()
        cardCreatedAt.name = "createdAt"
        cardCreatedAt.attributeType = .dateAttributeType

        let cardDueDate = NSAttributeDescription()
        cardDueDate.name = "dueDate"
        cardDueDate.attributeType = .dateAttributeType
        cardDueDate.isOptional = true

        let cardIsArchived = NSAttributeDescription()
        cardIsArchived.name = "isArchived"
        cardIsArchived.attributeType = .booleanAttributeType
        cardIsArchived.defaultValue = false

        let cardIsPinned = NSAttributeDescription()
        cardIsPinned.name = "isPinned"
        cardIsPinned.attributeType = .booleanAttributeType
        cardIsPinned.defaultValue = false

        let cardLabels = NSAttributeDescription()
        cardLabels.name = "labels"
        cardLabels.attributeType = .stringAttributeType
        cardLabels.isOptional = true

        cardEntity.properties = [cardId, cardTitle, cardDescription, cardSortOrder, cardCreatedAt, cardDueDate, cardIsArchived, cardIsPinned, cardLabels]

        // MARK: - Folder Attributes

        let folderId = NSAttributeDescription()
        folderId.name = "id"
        folderId.attributeType = .UUIDAttributeType

        let folderName = NSAttributeDescription()
        folderName.name = "name"
        folderName.attributeType = .stringAttributeType
        folderName.defaultValue = ""

        let folderSortOrder = NSAttributeDescription()
        folderSortOrder.name = "sortOrder"
        folderSortOrder.attributeType = .integer16AttributeType
        folderSortOrder.defaultValue = Int16(0)

        folderEntity.properties = [folderId, folderName, folderSortOrder]

        // MARK: - Note Attributes

        let noteId = NSAttributeDescription()
        noteId.name = "id"
        noteId.attributeType = .UUIDAttributeType

        let noteTitle = NSAttributeDescription()
        noteTitle.name = "title"
        noteTitle.attributeType = .stringAttributeType
        noteTitle.defaultValue = ""

        let noteContent = NSAttributeDescription()
        noteContent.name = "content"
        noteContent.attributeType = .binaryDataAttributeType
        noteContent.isOptional = true

        let noteCreatedAt = NSAttributeDescription()
        noteCreatedAt.name = "createdAt"
        noteCreatedAt.attributeType = .dateAttributeType

        let noteUpdatedAt = NSAttributeDescription()
        noteUpdatedAt.name = "updatedAt"
        noteUpdatedAt.attributeType = .dateAttributeType

        let noteIsPlainText = NSAttributeDescription()
        noteIsPlainText.name = "isPlainText"
        noteIsPlainText.attributeType = .booleanAttributeType
        noteIsPlainText.defaultValue = false

        noteEntity.properties = [noteId, noteTitle, noteContent, noteCreatedAt, noteUpdatedAt, noteIsPlainText]

        // MARK: - AuditLog Attributes

        let auditId = NSAttributeDescription()
        auditId.name = "id"
        auditId.attributeType = .UUIDAttributeType

        let auditTimestamp = NSAttributeDescription()
        auditTimestamp.name = "timestamp"
        auditTimestamp.attributeType = .dateAttributeType

        let auditEntityType = NSAttributeDescription()
        auditEntityType.name = "entityType"
        auditEntityType.attributeType = .stringAttributeType
        auditEntityType.defaultValue = ""

        let auditEntityId = NSAttributeDescription()
        auditEntityId.name = "entityId"
        auditEntityId.attributeType = .UUIDAttributeType

        let auditAction = NSAttributeDescription()
        auditAction.name = "action"
        auditAction.attributeType = .stringAttributeType
        auditAction.defaultValue = ""

        let auditDetails = NSAttributeDescription()
        auditDetails.name = "details"
        auditDetails.attributeType = .stringAttributeType
        auditDetails.defaultValue = "{}"

        auditLogEntity.properties = [auditId, auditTimestamp, auditEntityType, auditEntityId, auditAction, auditDetails]

        // MARK: - Relationships

        // Board <-> BoardColumn
        let boardColumnsRel = NSRelationshipDescription()
        boardColumnsRel.name = "columns"
        boardColumnsRel.destinationEntity = boardColumnEntity
        boardColumnsRel.minCount = 0
        boardColumnsRel.maxCount = 0 // to-many
        boardColumnsRel.deleteRule = .cascadeDeleteRule

        let columnBoardRel = NSRelationshipDescription()
        columnBoardRel.name = "board"
        columnBoardRel.destinationEntity = boardEntity
        columnBoardRel.minCount = 0
        columnBoardRel.maxCount = 1 // to-one
        columnBoardRel.deleteRule = .nullifyDeleteRule

        boardColumnsRel.inverseRelationship = columnBoardRel
        columnBoardRel.inverseRelationship = boardColumnsRel

        boardEntity.properties.append(boardColumnsRel)
        boardColumnEntity.properties.append(columnBoardRel)

        // BoardColumn <-> Card
        let columnCardsRel = NSRelationshipDescription()
        columnCardsRel.name = "cards"
        columnCardsRel.destinationEntity = cardEntity
        columnCardsRel.minCount = 0
        columnCardsRel.maxCount = 0 // to-many
        columnCardsRel.deleteRule = .cascadeDeleteRule

        let cardColumnRel = NSRelationshipDescription()
        cardColumnRel.name = "column"
        cardColumnRel.destinationEntity = boardColumnEntity
        cardColumnRel.minCount = 0
        cardColumnRel.maxCount = 1 // to-one
        cardColumnRel.deleteRule = .nullifyDeleteRule

        columnCardsRel.inverseRelationship = cardColumnRel
        cardColumnRel.inverseRelationship = columnCardsRel

        boardColumnEntity.properties.append(columnCardsRel)
        cardEntity.properties.append(cardColumnRel)

        // Folder <-> Folder (parent/children)
        let folderParentRel = NSRelationshipDescription()
        folderParentRel.name = "parent"
        folderParentRel.destinationEntity = folderEntity
        folderParentRel.minCount = 0
        folderParentRel.maxCount = 1 // to-one, optional
        folderParentRel.isOptional = true
        folderParentRel.deleteRule = .nullifyDeleteRule

        let folderChildrenRel = NSRelationshipDescription()
        folderChildrenRel.name = "children"
        folderChildrenRel.destinationEntity = folderEntity
        folderChildrenRel.minCount = 0
        folderChildrenRel.maxCount = 0 // to-many
        folderChildrenRel.deleteRule = .cascadeDeleteRule

        folderParentRel.inverseRelationship = folderChildrenRel
        folderChildrenRel.inverseRelationship = folderParentRel

        folderEntity.properties.append(contentsOf: [folderParentRel, folderChildrenRel])

        // Folder <-> Note
        let folderNotesRel = NSRelationshipDescription()
        folderNotesRel.name = "notes"
        folderNotesRel.destinationEntity = noteEntity
        folderNotesRel.minCount = 0
        folderNotesRel.maxCount = 0 // to-many
        folderNotesRel.deleteRule = .cascadeDeleteRule

        let noteFolderRel = NSRelationshipDescription()
        noteFolderRel.name = "folder"
        noteFolderRel.destinationEntity = folderEntity
        noteFolderRel.minCount = 0
        noteFolderRel.maxCount = 1 // to-one
        noteFolderRel.deleteRule = .nullifyDeleteRule

        folderNotesRel.inverseRelationship = noteFolderRel
        noteFolderRel.inverseRelationship = folderNotesRel

        folderEntity.properties.append(folderNotesRel)
        noteEntity.properties.append(noteFolderRel)

        // MARK: - Assign entities to model

        model.entities = [
            boardEntity,
            boardColumnEntity,
            cardEntity,
            folderEntity,
            noteEntity,
            auditLogEntity
        ]

        return model
    }
}
