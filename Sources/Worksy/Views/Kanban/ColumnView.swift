import SwiftUI
import CoreData

struct ColumnView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var column: BoardColumn

    let accentColor: Color

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false
    @State private var isDropTargeted = false
    @State private var showWipSettings = false
    @State private var wipLimitText = ""

    private var sortedCards: [Card] {
        column.activeCards
            .sorted {
                // Pinned cards first, then by sortOrder
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.sortOrder < $1.sortOrder
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colored accent bar at top
            accentColor
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 8, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 8
                ))

            // Column header
            columnHeader
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Divider().background(AppTheme.textMuted.opacity(0.3))

            // Cards list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(sortedCards, id: \.id) { card in
                        CardView(card: card, accentColor: accentColor)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: .infinity)
            .dropDestination(for: String.self) { droppedItems, _ in
                guard let cardIdString = droppedItems.first else { return false }
                return handleCardDrop(cardIdString: cardIdString, atIndex: sortedCards.count)
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
        }
        .frame(width: 280)
        .background(isDropTargeted ? accentColor.opacity(0.08) : AppTheme.card.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isDropTargeted ? accentColor.opacity(0.5) : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .draggable(column.id?.uuidString ?? "col:") {
            Text(column.name ?? "Column")
                .font(.system(size: 13, weight: .semibold))
                .padding(10)
                .frame(width: 200)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.3), radius: 4)
        }
        .alert("Delete Column", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteColumn() }
        } message: {
            Text("Are you sure you want to delete \"\(column.name ?? "this column")\"? All cards in this column will also be deleted.")
        }
        .popover(isPresented: $showWipSettings, arrowEdge: .bottom) {
            VStack(spacing: 8) {
                Text("WIP Limit")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                TextField("0 = no limit", text: $wipLimitText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit {
                        column.wipLimit = Int16(wipLimitText) ?? 0
                        try? viewContext.save()
                        showWipSettings = false
                    }
            }
            .padding(12)
            .background(AppTheme.background)
        }
    }

    // MARK: - Column Header

    @ViewBuilder
    private var columnHeader: some View {
        HStack {
            if isRenaming {
                TextField("Column name", text: $renameText, onCommit: { commitRename() })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            } else {
                Text(column.name ?? "Untitled")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            // WIP limit indicator
            if column.wipLimit > 0 {
                Text("\(sortedCards.count)/\(column.wipLimit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(column.isOverWipLimit ? .white : AppTheme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(column.isOverWipLimit ? Color(hex: "#FF3B30") : AppTheme.surface.opacity(0.8))
                    .clipShape(Capsule())
            }

            Text("\(sortedCards.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.surface.opacity(0.8))
                .clipShape(Capsule())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: sortedCards.count)

            Button(action: { addCard() }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button("Rename") {
                renameText = column.name ?? ""
                isRenaming = true
            }
            Button("Set WIP Limit") {
                wipLimitText = column.wipLimit > 0 ? "\(column.wipLimit)" : ""
                showWipSettings = true
            }
            Divider()
            Button("Delete", role: .destructive) { showDeleteConfirmation = true }
        }
    }

    // MARK: - Drag & Drop

    private func handleCardDrop(cardIdString: String, atIndex index: Int) -> Bool {
        guard let cardUUID = UUID(uuidString: cardIdString) else { return false }
        let request = NSFetchRequest<Card>(entityName: "Card")
        request.predicate = NSPredicate(format: "id == %@", cardUUID as CVarArg)
        request.fetchLimit = 1
        guard let card = try? viewContext.fetch(request).first else { return false }

        let oldColumn = card.column
        let oldColumnName = oldColumn?.name ?? "Unknown"
        let newColumnName = column.name ?? "Unknown"

        card.column = column

        var cards = sortedCards.filter { $0.id != card.id }
        let insertAt = min(index, cards.count)
        cards.insert(card, at: insertAt)
        for (i, c) in cards.enumerated() { c.sortOrder = Int16(i) }

        if oldColumn?.id != column.id {
            AuditService.shared.logMove(
                entityType: "Card", entityId: cardUUID,
                fromColumn: oldColumnName, toColumn: newColumnName, context: viewContext
            )
        }

        try? viewContext.save()
        return true
    }

    // MARK: - CRUD

    private func addCard() {
        let existingCards = sortedCards
        let nextOrder = (existingCards.last.map { Int($0.sortOrder) } ?? -1) + 1
        let card = Card(context: viewContext, title: "New Card", column: column)
        card.sortOrder = Int16(nextOrder)
        AuditService.shared.logCreate(
            entityType: "Card", entityId: card.id!,
            details: ["title": "New Card", "column": column.name ?? "Unknown"], context: viewContext
        )
        try? viewContext.save()
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != column.name {
            let oldName = column.name
            column.name = trimmed
            AuditService.shared.logUpdate(
                entityType: "BoardColumn", entityId: column.id!,
                field: "name", oldValue: oldName, newValue: trimmed, context: viewContext
            )
            try? viewContext.save()
        }
        isRenaming = false; renameText = ""
    }

    private func deleteColumn() {
        let columnId = column.id ?? UUID()
        let columnName = column.name ?? "Unknown"
        let cards = column.cards?.allObjects as? [Card] ?? []
        for card in cards {
            AuditService.shared.logDelete(
                entityType: "Card", entityId: card.id ?? UUID(),
                details: ["title": card.title ?? "Unknown", "reason": "column_deleted"], context: viewContext
            )
            viewContext.delete(card)
        }
        AuditService.shared.logDelete(
            entityType: "BoardColumn", entityId: columnId,
            details: ["name": columnName, "cardsDeleted": cards.count], context: viewContext
        )
        viewContext.delete(column)
        try? viewContext.save()
    }
}
