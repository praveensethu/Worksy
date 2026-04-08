import SwiftUI
import CoreData

struct NoteEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var note: Note

    @State private var editableTitle: String = ""
    @State private var attributedText: NSAttributedString = NSAttributedString(string: "")
    @State private var plainText: String = ""
    @StateObject private var editorState = RichTextEditorState()
    @State private var saveTimer: Timer?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Title row with mode toggle
                HStack {
                    TextField("Note title", text: $editableTitle, onCommit: {
                        saveTitle()
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    // Editor mode toggle
                    Button(action: { toggleEditorMode() }) {
                        HStack(spacing: 4) {
                            Image(systemName: note.isPlainText ? "textformat" : "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 11, weight: .medium))
                            Text(note.isPlainText ? "Rich Text" : "Plain Text")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.card.opacity(0.6))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(note.isPlainText ? "Switch to rich text editor" : "Switch to plain text editor")
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 12)

                Divider()
                    .background(AppTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 32)

                if note.isPlainText {
                    // Plain text mode — no toolbar, monospace
                    PlainTextEditor(
                        text: $plainText,
                        onTextChange: {
                            scheduleSave()
                        }
                    )
                } else {
                    // Rich text mode — toolbar + rich editor
                    EditorToolbar(editorState: editorState)
                        .padding(.top, 4)

                    Divider()
                        .background(AppTheme.textMuted.opacity(0.3))

                    RichTextEditor(
                        attributedText: $attributedText,
                        editorState: editorState,
                        onTextChange: {
                            scheduleSave()
                        }
                    )
                }
            }
        }
        .onAppear {
            loadNote()
        }
        .onChange(of: note.id) {
            loadNote()
        }
        .onDisappear {
            saveTimer?.invalidate()
            saveContent()
        }
    }

    // MARK: - Toggle mode

    private func toggleEditorMode() {
        saveContent()

        if note.isPlainText {
            // Switching to rich text — convert plain text to attributed string
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xE8 / 255.0, alpha: 1.0)
            ]
            attributedText = NSAttributedString(string: plainText, attributes: attrs)
        } else {
            // Switching to plain text — extract text from attributed string
            plainText = attributedText.string
        }

        note.isPlainText.toggle()
        note.updatedAt = Date()
        AuditService.shared.logUpdate(
            entityType: "Note",
            entityId: note.id ?? UUID(),
            field: "isPlainText",
            oldValue: String(!note.isPlainText),
            newValue: String(note.isPlainText),
            context: viewContext
        )
        try? viewContext.save()
    }

    // MARK: - Load

    private func loadNote() {
        editableTitle = note.title ?? ""

        if note.isPlainText {
            // Plain text: try to load as string from content, or extract from attributed string
            if let data = note.content {
                if let str = String(data: data, encoding: .utf8) {
                    plainText = str
                } else if let attrString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
                    plainText = attrString.string
                } else {
                    plainText = ""
                }
            } else {
                plainText = ""
            }
        } else {
            if let data = note.content,
               let attrString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
                attributedText = attrString
            } else {
                attributedText = NSAttributedString(string: "")
            }
        }
    }

    // MARK: - Save title

    private func saveTitle() {
        let trimmed = editableTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != note.title else { return }
        let oldTitle = note.title
        note.title = trimmed
        note.updatedAt = Date()
        AuditService.shared.logUpdate(
            entityType: "Note",
            entityId: note.id ?? UUID(),
            field: "title",
            oldValue: oldTitle,
            newValue: trimmed,
            context: viewContext
        )
        try? viewContext.save()
    }

    // MARK: - Debounced content save

    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            DispatchQueue.main.async {
                saveContent()
            }
        }
    }

    private func saveContent() {
        let data: Data?

        if note.isPlainText {
            data = plainText.data(using: .utf8)
        } else {
            data = try? NSKeyedArchiver.archivedData(withRootObject: attributedText, requiringSecureCoding: false)
        }

        guard let data else { return }

        if data != note.content {
            note.content = data
            note.updatedAt = Date()
            AuditService.shared.logUpdate(
                entityType: "Note",
                entityId: note.id ?? UUID(),
                field: "content",
                oldValue: nil,
                newValue: "content updated",
                context: viewContext
            )
            try? viewContext.save()
        }
    }
}
