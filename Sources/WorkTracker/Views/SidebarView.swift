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
    @State private var addingSubfolderToFolderId: UUID?
    @State private var newSubfolderName = ""
    @State private var folderToDelete: Folder?
    @State private var showDeleteFolderAlert = false

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
        .alert("Delete Folder?", isPresented: $showDeleteFolderAlert, presenting: folderToDelete) { folder in
            Button("Cancel", role: .cancel) {
                folderToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteFolder(folder)
                folderToDelete = nil
            }
        } message: { folder in
            Text("This will permanently delete \"\(folder.name ?? "Untitled")\" and all its subfolders and notes.")
        }
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

    private func folderRow(_ folder: Folder) -> AnyView {
        AnyView(
            DisclosureGroup {
                // Subfolders
                let subfolders = (folder.children?.allObjects as? [Folder] ?? [])
                    .sorted { ($0.name ?? "") < ($1.name ?? "") }
                ForEach(subfolders, id: \.id) { subfolder in
                    if renamingFolderId == subfolder.id {
                        TextField("Folder name", text: $renameText, onCommit: {
                            renameFolder(subfolder)
                        })
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textPrimary)
                    } else {
                        folderRow(subfolder)
                    }
                }

                if addingSubfolderToFolderId == folder.id {
                    TextField("New subfolder name", text: $newSubfolderName, onCommit: {
                        addSubfolder(to: folder)
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                }

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
                        .foregroundColor(Color(hex: "#14B8A6"))
                    Text(folder.name ?? "Untitled")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                }
            }
            .contextMenu {
                Button("Add Subfolder") {
                    newSubfolderName = ""
                    addingSubfolderToFolderId = folder.id
                }
                Button("Add Note") {
                    newNoteName = ""
                    addingNoteToFolderId = folder.id
                }
                Divider()
                Button("Rename") {
                    renameText = folder.name ?? ""
                    renamingFolderId = folder.id
                }
                Divider()
                Button("Delete", role: .destructive) {
                    folderToDelete = folder
                    showDeleteFolderAlert = true
                }
            }
        )
    }

    // MARK: - Note Row

    @ViewBuilder
    private func noteRow(_ note: Note) -> some View {
        let isSelected = selectedNoteId == note.id
        HStack(spacing: 6) {
            Image(systemName: "doc.text.fill")
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
        let trimmedName = newBoardName.trimmingCharacters(in: .whitespaces)
        let board = Board(context: viewContext, name: trimmedName, color: color)
        board.sortOrder = Int16(boards.count)

        // Create default columns
        let defaultColumns = ["To Do", "In Progress", "Done"]
        for (index, columnName) in defaultColumns.enumerated() {
            let col = BoardColumn(context: viewContext, name: columnName, board: board)
            col.sortOrder = Int16(index)
            AuditService.shared.logCreate(
                entityType: "BoardColumn",
                entityId: col.id!,
                details: ["name": columnName, "board": trimmedName],
                context: viewContext
            )
        }

        AuditService.shared.logCreate(
            entityType: "Board",
            entityId: board.id!,
            details: ["name": trimmedName, "color": color],
            context: viewContext
        )

        try? viewContext.save()
        isAddingBoard = false
        newBoardName = ""
    }

    private func deleteBoard(_ board: Board) {
        let boardId = board.id ?? UUID()
        let boardName = board.name ?? "Unknown"

        AuditService.shared.logDelete(
            entityType: "Board",
            entityId: boardId,
            details: ["name": boardName],
            context: viewContext
        )

        viewContext.delete(board)
        try? viewContext.save()
        if selectedBoardId == board.id {
            selectedBoardId = nil
        }
    }

    private func renameBoard(_ board: Board) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != board.name {
            let oldName = board.name
            board.name = trimmed

            AuditService.shared.logUpdate(
                entityType: "Board",
                entityId: board.id!,
                field: "name",
                oldValue: oldName,
                newValue: trimmed,
                context: viewContext
            )

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
        let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
        let folder = Folder(context: viewContext, name: trimmed)
        AuditService.shared.logCreate(
            entityType: "Folder",
            entityId: folder.id ?? UUID(),
            details: ["name": trimmed],
            context: viewContext
        )
        try? viewContext.save()
        isAddingFolder = false
        newFolderName = ""
    }

    private func addSubfolder(to parent: Folder) {
        guard !newSubfolderName.trimmingCharacters(in: .whitespaces).isEmpty else {
            addingSubfolderToFolderId = nil
            return
        }
        let trimmed = newSubfolderName.trimmingCharacters(in: .whitespaces)
        let subfolder = Folder(context: viewContext, name: trimmed, parent: parent)
        AuditService.shared.logCreate(
            entityType: "Folder",
            entityId: subfolder.id ?? UUID(),
            details: [
                "name": trimmed,
                "parentId": parent.id?.uuidString ?? "",
                "parentName": parent.name ?? ""
            ],
            context: viewContext
        )
        try? viewContext.save()
        addingSubfolderToFolderId = nil
        newSubfolderName = ""
    }

    private func deleteFolder(_ folder: Folder) {
        let folderId = folder.id ?? UUID()
        let folderName = folder.name ?? ""
        AuditService.shared.logDelete(
            entityType: "Folder",
            entityId: folderId,
            details: ["name": folderName],
            context: viewContext
        )
        deleteFolderContentsRecursively(folder)
        viewContext.delete(folder)
        try? viewContext.save()
    }

    private func deleteFolderContentsRecursively(_ folder: Folder) {
        for note in (folder.notes?.allObjects as? [Note] ?? []) {
            if selectedNoteId == note.id {
                selectedNoteId = nil
            }
            AuditService.shared.logDelete(
                entityType: "Note",
                entityId: note.id ?? UUID(),
                details: ["title": note.title ?? ""],
                context: viewContext
            )
            viewContext.delete(note)
        }
        for child in (folder.children?.allObjects as? [Folder] ?? []) {
            AuditService.shared.logDelete(
                entityType: "Folder",
                entityId: child.id ?? UUID(),
                details: ["name": child.name ?? ""],
                context: viewContext
            )
            deleteFolderContentsRecursively(child)
            viewContext.delete(child)
        }
    }

    private func renameFolder(_ folder: Folder) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != folder.name {
            let oldName = folder.name
            folder.name = trimmed
            AuditService.shared.logUpdate(
                entityType: "Folder",
                entityId: folder.id ?? UUID(),
                field: "name",
                oldValue: oldName,
                newValue: trimmed,
                context: viewContext
            )
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
        let trimmed = newNoteName.trimmingCharacters(in: .whitespaces)
        let note = Note(context: viewContext, title: trimmed, folder: folder)
        AuditService.shared.logCreate(
            entityType: "Note",
            entityId: note.id ?? UUID(),
            details: [
                "title": trimmed,
                "folderId": folder.id?.uuidString ?? "",
                "folderName": folder.name ?? ""
            ],
            context: viewContext
        )
        try? viewContext.save()
        addingNoteToFolderId = nil
        newNoteName = ""
    }

    private func deleteNote(_ note: Note) {
        let noteId = note.id ?? UUID()
        AuditService.shared.logDelete(
            entityType: "Note",
            entityId: noteId,
            details: ["title": note.title ?? ""],
            context: viewContext
        )
        if selectedNoteId == noteId {
            selectedNoteId = nil
        }
        viewContext.delete(note)
        try? viewContext.save()
    }

    private func renameNote(_ note: Note) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != note.title {
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
        renamingNoteId = nil
        renameText = ""
    }
}
