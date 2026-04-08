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
            // Pin indicator + title
            HStack(spacing: 4) {
                if card.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "#FFB800"))
                }
                Text(card.title ?? "Untitled")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            if let desc = card.cardDescription, !desc.isEmpty {
                Text(desc.components(separatedBy: .newlines).first ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(1)
            }

            // Labels row
            let labels = card.labelArray
            if !labels.isEmpty {
                HStack(spacing: 3) {
                    ForEach(labels.prefix(3), id: \.self) { label in
                        LabelBadge(label: label)
                    }
                    if labels.count > 3 {
                        Text("+\(labels.count - 3)")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }

            // Due date
            if let due = card.dueDate {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                    Text(due, style: .date)
                        .font(.system(size: 10))
                }
                .foregroundColor(card.isOverdue ? Color(hex: "#FF3B30") : AppTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    card.isOverdue ? Color(hex: "#FF3B30").opacity(0.6) :
                    isHovered ? accentColor : AppTheme.textMuted.opacity(0.2),
                    lineWidth: card.isOverdue ? 1.5 : isHovered ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(isHovered ? 0.35 : 0.15), radius: isHovered ? 6 : 2, x: 0, y: isHovered ? 3 : 1)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .draggable(card.id?.uuidString ?? "") {
            Text(card.title ?? "Untitled")
                .font(.system(size: 13))
                .padding(10)
                .frame(width: 260)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            showDetailSheet = true
        }
        .contextMenu {
            Button("Edit") { showDetailSheet = true }
            Button("View History") { showHistorySheet = true }
            Divider()
            Button(card.isPinned ? "Unpin" : "Pin to Top") { togglePin() }
            Button("Archive") { archiveCard() }
            Divider()
            Button("Mark as Done") { markAsDone() }
            Button("Delete", role: .destructive) { showDeleteConfirmation = true }
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
            Button("Delete", role: .destructive) { deleteCard() }
        } message: {
            Text("Are you sure you want to delete \"\(card.title ?? "this card")\"?")
        }
    }

    private func togglePin() {
        card.isPinned.toggle()
        AuditService.shared.logUpdate(
            entityType: "Card", entityId: card.id ?? UUID(),
            field: "isPinned", oldValue: String(!card.isPinned), newValue: String(card.isPinned),
            context: viewContext
        )
        try? viewContext.save()
    }

    private func archiveCard() {
        card.isArchived = true
        AuditService.shared.logUpdate(
            entityType: "Card", entityId: card.id ?? UUID(),
            field: "isArchived", oldValue: "false", newValue: "true",
            context: viewContext
        )
        try? viewContext.save()
    }

    private func markAsDone() {
        AuditService.shared.logDelete(
            entityType: "Card", entityId: card.id ?? UUID(),
            details: ["title": card.title ?? "Unknown", "column": card.column?.name ?? "Unknown", "reason": "marked_done"],
            context: viewContext
        )
        viewContext.delete(card)
        try? viewContext.save()
    }

    private func deleteCard() {
        AuditService.shared.logDelete(
            entityType: "Card", entityId: card.id ?? UUID(),
            details: ["title": card.title ?? "Unknown", "column": card.column?.name ?? "Unknown"],
            context: viewContext
        )
        viewContext.delete(card)
        try? viewContext.save()
    }
}
