import SwiftUI
import CoreData

struct NoteDetailPlaceholder: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var note: Note

    @State private var editableTitle: String = ""

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // Editable title
                TextField("Note title", text: $editableTitle, onCommit: {
                    saveTitle()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 32)
                .padding(.top, 32)

                Divider()
                    .background(AppTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 32)

                // Placeholder for rich text editor
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textMuted)
                    Text("Rich text editor coming soon...")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()
            }
        }
        .onAppear {
            editableTitle = note.title ?? ""
        }
        .onChange(of: note.id) { _ in
            editableTitle = note.title ?? ""
        }
    }

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
}
