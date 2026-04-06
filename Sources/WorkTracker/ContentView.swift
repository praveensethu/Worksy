import SwiftUI

struct ContentView: View {
    @State private var selectedBoardId: UUID?
    @State private var selectedNoteId: UUID?

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedBoardId: $selectedBoardId,
                selectedNoteId: $selectedNoteId
            )
        } detail: {
            if let boardId = selectedBoardId {
                // KanbanBoardView placeholder
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    Text("Board: \(boardId)")
                        .foregroundColor(AppTheme.textPrimary)
                }
            } else if let noteId = selectedNoteId {
                // NoteEditorView placeholder
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    Text("Note: \(noteId)")
                        .foregroundColor(AppTheme.textPrimary)
                }
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
