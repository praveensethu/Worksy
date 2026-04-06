import SwiftUI
import CoreData

struct CardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var card: Card

    let accentColor: Color

    @State private var isHovered = false
    @State private var showDetailSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showHistorySheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.title ?? "Untitled")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if let desc = card.cardDescription, !desc.isEmpty {
                Text(desc.components(separatedBy: .newlines).first ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isHovered ? accentColor : AppTheme.textMuted.opacity(0.2),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            showDetailSheet = true
        }
        .contextMenu {
            Button("Edit") {
                showDetailSheet = true
            }
            Button("View History") {
                showHistorySheet = true
            }
            Divider()
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            CardDetailSheet(card: card, accentColor: accentColor)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showHistorySheet) {
            CardDetailSheet(card: card, accentColor: accentColor, scrollToHistory: true)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Delete Card", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("Are you sure you want to delete \"\(card.title ?? "this card")\"?")
        }
    }

    private func deleteCard() {
        let cardId = card.id ?? UUID()
        let cardTitle = card.title ?? "Unknown"
        let columnName = card.column?.name ?? "Unknown"

        AuditService.shared.logDelete(
            entityType: "Card",
            entityId: cardId,
            details: ["title": cardTitle, "column": columnName],
            context: viewContext
        )

        viewContext.delete(card)
        try? viewContext.save()
    }
}
