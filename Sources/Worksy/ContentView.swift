import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedBoardId: UUID?
    @State private var selectedNoteId: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showSearch = false
    @State private var showActivityFeed = false
    @State private var showTemplates = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedBoardId: $selectedBoardId,
                selectedNoteId: $selectedNoteId
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 320)
        } detail: {
            if showSearch {
                SearchView(selectedBoardId: $selectedBoardId, selectedNoteId: $selectedNoteId)
            } else if let boardId = selectedBoardId, let board = fetchBoard(id: boardId) {
                KanbanBoardView(board: board)
                    .id(boardId)
            } else if let noteId = selectedNoteId, let note = fetchNote(id: noteId) {
                NoteEditorView(note: note)
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .sheet(isPresented: $showActivityFeed) {
            ActivityFeedView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showTemplates) {
            BoardTemplatePickerView(selectedBoardId: $selectedBoardId)
                .environment(\.managedObjectContext, viewContext)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                }
                .help("Search (Cmd+F)")

                Button(action: { showTemplates.toggle() }) {
                    Image(systemName: "rectangle.stack.badge.plus")
                }
                .help("New from template")

                Button(action: { showActivityFeed.toggle() }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .help("Activity feed")
            }
        }
    }

    private func fetchBoard(id: UUID) -> Board? {
        let request = NSFetchRequest<Board>(entityName: "Board")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    private func fetchNote(id: UUID) -> Note? {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
}

#Preview {
    ContentView()
}
