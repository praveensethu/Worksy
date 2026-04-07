import SwiftUI
import CoreData

struct ArchiveView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var board: Board

    private var archivedCards: [Card] {
        let allColumns = board.columns?.allObjects as? [BoardColumn] ?? []
        return allColumns.flatMap { col in
            (col.cards?.allObjects as? [Card] ?? []).filter { $0.isArchived }
        }.sorted { ($0.title ?? "") < ($1.title ?? "") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(AppTheme.textMuted)
                Text("Archived Cards")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(archivedCards.count) cards")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }

            if archivedCards.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textMuted)
                    Text("No archived cards")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(archivedCards, id: \.id) { card in
                            archivedCardRow(card)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 450, height: 500)
        .background(AppTheme.background)
    }

    @ViewBuilder
    private func archivedCardRow(_ card: Card) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(card.title ?? "Untitled")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                Text("from \(card.column?.name ?? "Unknown")")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
            }

            Spacer()

            Button("Restore") {
                card.isArchived = false
                AuditService.shared.logUpdate(
                    entityType: "Card",
                    entityId: card.id ?? UUID(),
                    field: "isArchived",
                    oldValue: "true",
                    newValue: "false",
                    context: viewContext
                )
                try? viewContext.save()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(hex: "#00D68F"))

            Button(action: {
                AuditService.shared.logDelete(
                    entityType: "Card",
                    entityId: card.id ?? UUID(),
                    details: ["title": card.title ?? "Unknown"],
                    context: viewContext
                )
                viewContext.delete(card)
                try? viewContext.save()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#FF6B6B"))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
