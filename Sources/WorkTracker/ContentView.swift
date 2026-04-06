import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedBoardId: UUID?
    @State private var selectedNoteId: UUID?

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedBoardId: $selectedBoardId,
                selectedNoteId: $selectedNoteId
            )
        } detail: {
            if let boardId = selectedBoardId, let board = fetchBoard(id: boardId) {
                KanbanBoardView(board: board)
            } else if let noteId = selectedNoteId, let note = fetchNote(id: noteId) {
                NoteDetailPlaceholder(note: note)
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
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
