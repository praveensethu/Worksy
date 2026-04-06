import SwiftUI
import CoreData

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: NSEntityDescription(),
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)]
    )
    private var boards: FetchedResults<Board>

    @FetchRequest(
        entity: NSEntityDescription(),
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
        predicate: NSPredicate(format: "parent == nil")
    )
    private var rootFolders: FetchedResults<Folder>

    @Binding var selectedBoardId: UUID?
    @Binding var selectedNoteId: UUID?

    @State private var isAddingBoard = false
    @State private var newBoardName = ""
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    @State private var renamingBoardId: UUID?
    @State private var renamingFolderId: UUID?
    @State private var renamingNoteId: UUID?
    @State private var renameText = ""
    @State private var addingNoteToFolderId: UUID?
    @State private var newNoteName = ""

    init(selectedBoardId: Binding<UUID?>, selectedNoteId: Binding<UUID?>) {
        _selectedBoardId = selectedBoardId
        _selectedNoteId = selectedNoteId

        let boardRequest: NSFetchRequest<Board> = NSFetchRequest(entityName: "Board")
        boardRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        _boards = FetchRequest(fetchRequest: boardRequest)

        let folderRequest: NSFetchRequest<Folder> = NSFetchRequest(entityName: "Folder")
        folderRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        folderRequest.predicate = NSPredicate(format: "parent == nil")
        _rootFolders = FetchRequest(fetchRequest: folderRequest)
    }

    var body: some View {
        List {
            // MARK: - Kanban Boards Section
            Section {
                ForEach(boards, id: \.id) { board in
                    if renamingBoardId == board.id {
                        TextField("Board name", text: $renameText, onCommit: {
                            renameBoard(board)
                        })
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textPrimary)
                    } else {
                        boardRow(board)
                    }
                }

                if isAddingBoard {
                    TextField("New board name", text: $newBoardName, onCommit: {
                        addBoard()
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                }
            } header: {
                HStack {
                    Text("KANBAN BOARDS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                    Spacer()
                    Button(action: {
                        isAddingBoard = true
                        newBoardName = ""
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: - Notebooks Section
            Section {
                ForEach(rootFolders, id: \.id) { folder in
                    if renamingFolderId == folder.id {
                        TextField("Folder name", text: $renameText, onCommit: {
                            renameFolder(folder)
                        })
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textPrimary)
                    } else {
                        folderRow(folder)
                    }
                }

                if isAddingFolder {
                    TextField("New folder name", text: $newFolderName, onCommit: {
                        addFolder()
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                }
            } header: {
                HStack {
                    Text("NOTEBOOKS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                    Spacer()
                    Button(action: {
                        isAddingFolder = true
                        newFolderName = ""
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppTheme.sidebar)
    }

    // MARK: - Board Row

    @ViewBuilder
    private func boardRow(_ board: Board) -> some View {
        let isSelected = selectedBoardId == board.id
        HStack(spacing: 8) {
            Circle()
                .fill(AppTheme.accentColor(for: board.color ?? "#007AFF"))
                .frame(width: 8, height: 8)
            Text(board.name ?? "Untitled")
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedBoardId = board.id
            selectedNoteId = nil
        }
        .contextMenu {
            Button("Rename") {
                renameText = board.name ?? ""
                renamingBoardId = board.id
            }
            Divider()
            Button("Delete", role: .destructive) {
                deleteBoard(board)
            }
        }
    }

    // MARK: - Folder Row

    @ViewBuilder
    private func folderRow(_ folder: Folder) -> some View {
        DisclosureGroup {
            // Notes inside this folder
            let folderNotes = (folder.notes?.allObjects as? [Note] ?? [])
                .sorted { ($0.title ?? "") < ($1.title ?? "") }
            ForEach(folderNotes, id: \.id) { note in
                if renamingNoteId == note.id {
                    TextField("Note name", text: $renameText, onCommit: {
                        renameNote(note)
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                } else {
                    noteRow(note)
                }
            }

            if addingNoteToFolderId == folder.id {
                TextField("New note name", text: $newNoteName, onCommit: {
                    addNote(to: folder)
                })
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                Text(folder.name ?? "Untitled")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }
        }
        .contextMenu {
            Button("Add Note") {
                newNoteName = ""
                addingNoteToFolderId = folder.id
            }
            Button("Rename") {
                renameText = folder.name ?? ""
                renamingFolderId = folder.id
            }
            Divider()
            Button("Delete", role: .destructive) {
                deleteFolder(folder)
            }
        }
    }

    // MARK: - Note Row

    @ViewBuilder
    private func noteRow(_ note: Note) -> some View {
        let isSelected = selectedNoteId == note.id
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
            Text(note.title ?? "Untitled")
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedNoteId = note.id
            selectedBoardId = nil
        }
        .contextMenu {
            Button("Rename") {
                renameText = note.title ?? ""
                renamingNoteId = note.id
            }
            Divider()
            Button("Delete", role: .destructive) {
                deleteNote(note)
            }
        }
    }

    // MARK: - CRUD Operations

    private func addBoard() {
        guard !newBoardName.trimmingCharacters(in: .whitespaces).isEmpty else {
            isAddingBoard = false
            return
        }
        let accentIndex = boards.count % AppTheme.accents.count
        let accentHexes = [
            "#0F9BF7", "#FF2D78", "#00D68F", "#FFB800",
            "#A855F7", "#FF6B6B", "#14B8A6", "#6366F1"
        ]
        let color = accentHexes[accentIndex]
        let _ = Board(context: viewContext, name: newBoardName.trimmingCharacters(in: .whitespaces), color: color)
        try? viewContext.save()
        isAddingBoard = false
        newBoardName = ""
    }

    private func deleteBoard(_ board: Board) {
        viewContext.delete(board)
        try? viewContext.save()
        if selectedBoardId == board.id {
            selectedBoardId = nil
        }
    }

    private func renameBoard(_ board: Board) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            board.name = trimmed
            try? viewContext.save()
        }
        renamingBoardId = nil
        renameText = ""
    }

    private func addFolder() {
        guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else {
            isAddingFolder = false
            return
        }
        let _ = Folder(context: viewContext, name: newFolderName.trimmingCharacters(in: .whitespaces))
        try? viewContext.save()
        isAddingFolder = false
        newFolderName = ""
    }

    private func deleteFolder(_ folder: Folder) {
        viewContext.delete(folder)
        try? viewContext.save()
    }

    private func renameFolder(_ folder: Folder) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            folder.name = trimmed
            try? viewContext.save()
        }
        renamingFolderId = nil
        renameText = ""
    }

    private func addNote(to folder: Folder) {
        guard !newNoteName.trimmingCharacters(in: .whitespaces).isEmpty else {
            addingNoteToFolderId = nil
            return
        }
        let _ = Note(context: viewContext, title: newNoteName.trimmingCharacters(in: .whitespaces), folder: folder)
        try? viewContext.save()
        addingNoteToFolderId = nil
        newNoteName = ""
    }

    private func deleteNote(_ note: Note) {
        if selectedNoteId == note.id {
            selectedNoteId = nil
        }
        viewContext.delete(note)
        try? viewContext.save()
    }

    private func renameNote(_ note: Note) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            note.title = trimmed
            try? viewContext.save()
        }
        renamingNoteId = nil
        renameText = ""
    }
}
