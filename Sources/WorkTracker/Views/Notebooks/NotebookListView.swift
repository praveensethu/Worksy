import SwiftUI
import CoreData

struct NotebookListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var rootFolders: FetchedResults<Folder>

    @Binding var selectedNoteId: UUID?

    init(selectedNoteId: Binding<UUID?>) {
        _selectedNoteId = selectedNoteId

        let request: NSFetchRequest<Folder> = NSFetchRequest(entityName: "Folder")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        request.predicate = NSPredicate(format: "parent == nil")
        _rootFolders = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if rootFolders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textMuted)
                    Text("No Notebooks Yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Create a folder in the sidebar to get started.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("All Notebooks")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 16)

                        ForEach(rootFolders, id: \.id) { folder in
                            notebookFolderSection(folder, depth: 0)
                        }
                    }
                }
            }
        }
    }

    private func notebookFolderSection(_ folder: Folder, depth: Int) -> AnyView {
        AnyView(VStack(alignment: .leading, spacing: 0) {
            // Folder header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#14B8A6"))
                Text(folder.name ?? "Untitled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(folderNotes(folder).count) notes")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.leading, CGFloat(depth) * 20)
            .padding(.vertical, 8)

            // Notes in this folder
            ForEach(folderNotes(folder), id: \.id) { note in
                let isSelected = selectedNoteId == note.id
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(note.title ?? "Untitled")
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? Color(hex: "#14B8A6") : AppTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let date = note.updatedAt {
                        Text(date, style: .date)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.leading, CGFloat(depth) * 20 + 22)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.card : Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedNoteId = note.id
                }
            }

            // Subfolders
            let subfolders = (folder.children?.allObjects as? [Folder] ?? [])
                .sorted { ($0.name ?? "") < ($1.name ?? "") }
            ForEach(subfolders, id: \.id) { subfolder in
                notebookFolderSection(subfolder, depth: depth + 1)
            }
        })
    }

    private func folderNotes(_ folder: Folder) -> [Note] {
        (folder.notes?.allObjects as? [Note] ?? [])
            .sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
}
