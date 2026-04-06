import SwiftUI
import CoreData

struct NoteEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var note: Note

    @State private var editableTitle: String = ""
    @State private var attributedText: NSAttributedString = NSAttributedString(string: "")
    @StateObject private var editorState = RichTextEditorState()
    @State private var saveTimer: Timer?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Editable title
                TextField("Note title", text: $editableTitle, onCommit: {
                    saveTitle()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 12)

                Divider()
                    .background(AppTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 32)

                // Formatting toolbar
                EditorToolbar(editorState: editorState)
                    .padding(.top, 4)

                Divider()
                    .background(AppTheme.textMuted.opacity(0.3))

                // Rich text editor
                RichTextEditor(
                    attributedText: $attributedText,
                    editorState: editorState,
                    onTextChange: {
                        scheduleSave()
                    }
                )
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

    // MARK: - Load

    private func loadNote() {
        editableTitle = note.title ?? ""

        if let data = note.content,
           let attrString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
            attributedText = attrString
        } else {
            attributedText = NSAttributedString(string: "")
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
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: attributedText, requiringSecureCoding: false) else { return }

        // Only save if content actually changed
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
