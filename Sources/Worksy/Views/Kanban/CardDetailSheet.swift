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
    @State private var editLabels: [String] = []
    @State private var editDueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var isPinned: Bool = false
    @State private var showMarkdownPreview = false
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
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundColor(AppTheme.textSecondary)
                    Button("Save") { saveChanges(); dismiss() }
                        .buttonStyle(.plain)
                        .foregroundColor(accentColor)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Divider().background(AppTheme.textMuted.opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
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
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 1))
                        }

                        // Description with markdown toggle
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Description")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.textMuted)
                                    .textCase(.uppercase)
                                Spacer()
                                Button(showMarkdownPreview ? "Edit" : "Preview") {
                                    showMarkdownPreview.toggle()
                                }
                                .font(.system(size: 11))
                                .buttonStyle(.plain)
                                .foregroundColor(accentColor)
                            }

                            if showMarkdownPreview {
                                MarkdownPreview(text: editDescription)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                TextEditor(text: $editDescription)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 100)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.textMuted.opacity(0.2), lineWidth: 1))
                            }
                        }

                        // Labels
                        LabelPickerView(selectedLabels: $editLabels)

                        // Due date
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("Due Date", isOn: $hasDueDate)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.textMuted)
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                            }
                            if hasDueDate {
                                DatePicker("", selection: $editDueDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.field)
                            }
                        }

                        // Pin toggle
                        Toggle("Pin to top of column", isOn: $isPinned)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .toggleStyle(.switch)
                            .controlSize(.mini)

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

                        Divider().background(AppTheme.textMuted.opacity(0.3))

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
                            withAnimation { proxy.scrollTo("historySection", anchor: .top) }
                        }
                    }
                }
            }
            .frame(minWidth: 450, minHeight: 550)
            .background(AppTheme.background)
            .onAppear {
                editTitle = card.title ?? ""
                editDescription = card.cardDescription ?? ""
                editLabels = card.labelArray
                hasDueDate = card.dueDate != nil
                editDueDate = card.dueDate ?? Date()
                isPinned = card.isPinned
                loadHistory()
            }
        }
    }

    // MARK: - History Row

    @ViewBuilder
    private func historyRow(_ entry: AuditLog) -> some View {
        HStack(alignment: .top, spacing: 10) {
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

    private func actionIcon(for action: String) -> Image {
        switch action {
        case "created": return Image(systemName: "plus.circle.fill")
        case "updated": return Image(systemName: "pencil.circle.fill")
        case "moved": return Image(systemName: "arrow.right.circle.fill")
        case "deleted": return Image(systemName: "trash.circle.fill")
        default: return Image(systemName: "circle.fill")
        }
    }

    private func actionColor(for action: String) -> Color {
        switch action {
        case "created": return Color(hex: "#00D68F")
        case "updated": return Color(hex: "#FFB800")
        case "moved": return Color(hex: "#A855F7")
        case "deleted": return Color(hex: "#FF6B6B")
        default: return AppTheme.textMuted
        }
    }

    private func actionLabel(for action: String, details: String) -> String {
        guard let data = details.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return action.capitalized
        }
        switch action {
        case "created": return "Card created"
        case "updated":
            if let field = parsed["field"] as? String { return "Updated \(field)" }
            return "Card updated"
        case "moved":
            let from = parsed["fromColumn"] as? String ?? "?"
            let to = parsed["toColumn"] as? String ?? "?"
            return "Moved from \(from) to \(to)"
        case "deleted": return "Card deleted"
        default: return action.capitalized
        }
    }

    // MARK: - Save

    private func saveChanges() {
        let trimmedTitle = editTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        let cardId = card.id ?? UUID()

        if trimmedTitle != card.title {
            AuditService.shared.logUpdate(entityType: "Card", entityId: cardId, field: "title", oldValue: card.title, newValue: trimmedTitle, context: viewContext)
            card.title = trimmedTitle
        }

        let trimmedDesc = editDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDesc != (card.cardDescription ?? "") {
            AuditService.shared.logUpdate(entityType: "Card", entityId: cardId, field: "description",
                oldValue: card.cardDescription?.isEmpty != false ? nil : card.cardDescription,
                newValue: trimmedDesc.isEmpty ? nil : trimmedDesc, context: viewContext)
            card.cardDescription = trimmedDesc
        }

        // Labels
        if editLabels != card.labelArray {
            card.labelArray = editLabels
        }

        // Due date
        let newDue = hasDueDate ? editDueDate : nil
        if newDue != card.dueDate {
            card.dueDate = newDue
        }

        // Pin
        if isPinned != card.isPinned {
            card.isPinned = isPinned
        }

        try? viewContext.save()
    }

    private func loadHistory() {
        guard let cardId = card.id else { return }
        auditHistory = AuditService.shared.history(for: cardId, context: viewContext)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }
    private var timestampFormatter: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short; return f
    }
}

// MARK: - Simple Markdown Preview

struct MarkdownPreview: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if line.hasPrefix("### ") {
                    Text(String(line.dropFirst(4)))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                } else if line.hasPrefix("## ") {
                    Text(String(line.dropFirst(3)))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                } else if line.hasPrefix("# ") {
                    Text(String(line.dropFirst(2)))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundColor(AppTheme.textMuted)
                        Text(renderInline(String(line.dropFirst(2))))
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else if line.hasPrefix("```") {
                    // skip fence lines
                } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 4)
                } else {
                    Text(renderInline(line))
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private func renderInline(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        // Bold
        while let range = result.range(of: "**") {
            if let endRange = result[range.upperBound...].range(of: "**") {
                let boldText = result[range.upperBound..<endRange.lowerBound]
                var bold = boldText
                bold.font = .system(size: 13, weight: .bold)
                result.replaceSubrange(range.lowerBound..<endRange.upperBound, with: bold)
            } else { break }
        }
        // Inline code
        while let range = result.range(of: "`") {
            if let endRange = result[range.upperBound...].range(of: "`") {
                let codeText = result[range.upperBound..<endRange.lowerBound]
                var code = codeText
                code.font = .system(size: 12, design: .monospaced)
                code.backgroundColor = Color(hex: "#2C2C2E")
                result.replaceSubrange(range.lowerBound..<endRange.upperBound, with: code)
            } else { break }
        }
        return result
    }
}
