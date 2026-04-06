import SwiftUI
import CoreData

struct ColumnView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var column: BoardColumn

    let accentColor: Color

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false

    private var sortedCards: [Card] {
        (column.cards?.allObjects as? [Card] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colored accent bar at top
            accentColor
                .frame(height: 3)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 8,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 8
                ))

            // Column header
            columnHeader
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Divider()
                .background(AppTheme.textMuted.opacity(0.3))

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
        }
        .frame(width: 280)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Delete Column", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteColumn()
            }
        } message: {
            Text("Are you sure you want to delete \"\(column.name ?? "this column")\"? All cards in this column will also be deleted.")
        }
    }

    // MARK: - Column Header

    @ViewBuilder
    private var columnHeader: some View {
        HStack {
            if isRenaming {
                TextField("Column name", text: $renameText, onCommit: {
                    commitRename()
                })
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

            Text("\(sortedCards.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.surface.opacity(0.8))
                .clipShape(Capsule())

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
            Divider()
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
    }


    // MARK: - CRUD Operations

    private func addCard() {
        let existingCards = sortedCards
        let nextOrder = (existingCards.last.map { Int($0.sortOrder) } ?? -1) + 1

        let card = Card(context: viewContext, title: "New Card", column: column)
        card.sortOrder = Int16(nextOrder)

        AuditService.shared.logCreate(
            entityType: "Card",
            entityId: card.id!,
            details: ["title": "New Card", "column": column.name ?? "Unknown"],
            context: viewContext
        )

        try? viewContext.save()
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != column.name {
            let oldName = column.name
            column.name = trimmed

            AuditService.shared.logUpdate(
                entityType: "BoardColumn",
                entityId: column.id!,
                field: "name",
                oldValue: oldName,
                newValue: trimmed,
                context: viewContext
            )

            try? viewContext.save()
        }
        isRenaming = false
        renameText = ""
    }

    private func deleteColumn() {
        let columnId = column.id ?? UUID()
        let columnName = column.name ?? "Unknown"

        // Delete all cards in this column
        let cards = column.cards?.allObjects as? [Card] ?? []
        for card in cards {
            AuditService.shared.logDelete(
                entityType: "Card",
                entityId: card.id ?? UUID(),
                details: ["title": card.title ?? "Unknown", "reason": "column_deleted"],
                context: viewContext
            )
            viewContext.delete(card)
        }

        AuditService.shared.logDelete(
            entityType: "BoardColumn",
            entityId: columnId,
            details: ["name": columnName, "cardsDeleted": cards.count],
            context: viewContext
        )

        viewContext.delete(column)
        try? viewContext.save()
    }
}
