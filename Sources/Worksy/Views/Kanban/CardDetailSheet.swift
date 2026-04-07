import SwiftUI
import CoreData

struct CardDetailSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var card: Card
    let accentColor: Color
    var scrollToHistory: Bool = false

    @State private var editTitle: String = ""
    @State private var editDescription: String = ""
    @State private var auditHistory: [AuditLog] = []

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                // Header bar
                HStack {
                    Text("Card Details")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(AppTheme.textSecondary)

                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(accentColor)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Divider()
                    .background(AppTheme.textMuted.opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .textCase(.uppercase)

                            TextField("Card title", text: $editTitle)
                                .textFieldStyle(.plain)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(10)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 1)
                                )
                        }

                        // Description field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .textCase(.uppercase)

                            TextEditor(text: $editDescription)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .frame(minHeight: 100)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 1)
                                )
                        }

                        // Created date
                        if let createdAt = card.createdAt {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                                Text("Created \(createdAt, formatter: dateFormatter)")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        Divider()
                            .background(AppTheme.textMuted.opacity(0.3))

                        // History section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted)
                                Text("History")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .id("historySection")

                            if auditHistory.isEmpty {
                                Text("No history yet.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(auditHistory, id: \.id) { entry in
                                        historyRow(entry)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .onAppear {
                    if scrollToHistory {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo("historySection", anchor: .top)
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 450)
            .background(AppTheme.background)
            .onAppear {
                editTitle = card.title ?? ""
                editDescription = card.cardDescription ?? ""
                loadHistory()
            }
        }
    }

    // MARK: - History Row

    @ViewBuilder
    private func historyRow(_ entry: AuditLog) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon
            actionIcon(for: entry.action ?? "")
                .font(.system(size: 10))
                .foregroundColor(actionColor(for: entry.action ?? ""))
                .frame(width: 20, height: 20)
                .background(actionColor(for: entry.action ?? "").opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(actionLabel(for: entry.action ?? "", details: entry.details ?? "{}"))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)

                if let timestamp = entry.timestamp {
                    Text(timestamp, formatter: timestampFormatter)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Action Helpers

    private func actionIcon(for action: String) -> Image {
        switch action {
        case "created":
            return Image(systemName: "plus.circle.fill")
        case "updated":
            return Image(systemName: "pencil.circle.fill")
        case "moved":
            return Image(systemName: "arrow.right.circle.fill")
        case "deleted":
            return Image(systemName: "trash.circle.fill")
        default:
            return Image(systemName: "circle.fill")
        }
    }

    private func actionColor(for action: String) -> Color {
        switch action {
        case "created":
            return Color(hex: "#00D68F")
        case "updated":
            return Color(hex: "#0F9BF7")
        case "moved":
            return Color(hex: "#FFB800")
        case "deleted":
            return Color(hex: "#FF6B6B")
        default:
            return AppTheme.textMuted
        }
    }

    private func actionLabel(for action: String, details: String) -> String {
        let parsed = parseDetails(details)

        switch action {
        case "created":
            return "Card created"
        case "updated":
            if let field = parsed["field"] as? String {
                return "Updated \(field)"
            }
            return "Card updated"
        case "moved":
            let from = parsed["fromColumn"] as? String ?? "?"
            let to = parsed["toColumn"] as? String ?? "?"
            return "Moved from \(from) to \(to)"
        case "deleted":
            return "Card deleted"
        default:
            return action.capitalized
        }
    }

    private func parseDetails(_ json: String) -> [String: Any] {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    // MARK: - Save

    private func saveChanges() {
        let trimmedTitle = editTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let cardId = card.id ?? UUID()

        // Log title change
        if trimmedTitle != card.title {
            AuditService.shared.logUpdate(
                entityType: "Card",
                entityId: cardId,
                field: "title",
                oldValue: card.title,
                newValue: trimmedTitle,
                context: viewContext
            )
            card.title = trimmedTitle
        }

        // Log description change
        let trimmedDesc = editDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldDesc = card.cardDescription ?? ""
        if trimmedDesc != oldDesc {
            AuditService.shared.logUpdate(
                entityType: "Card",
                entityId: cardId,
                field: "description",
                oldValue: oldDesc.isEmpty ? nil : oldDesc,
                newValue: trimmedDesc.isEmpty ? nil : trimmedDesc,
                context: viewContext
            )
            card.cardDescription = trimmedDesc
        }

        try? viewContext.save()
    }

    // MARK: - Load History

    private func loadHistory() {
        guard let cardId = card.id else { return }
        auditHistory = AuditService.shared.history(for: cardId, context: viewContext)
    }

    // MARK: - Formatters

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    private var timestampFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }
}
