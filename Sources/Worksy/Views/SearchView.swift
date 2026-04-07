import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedBoardId: UUID?
    @Binding var selectedNoteId: UUID?

    @State private var searchText = ""
    @State private var cardResults: [Card] = []
    @State private var noteResults: [Note] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                TextField("Search cards and notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textPrimary)
                    .onChange(of: searchText) { _ in performSearch() }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if searchText.isEmpty {
                VStack {
                    Spacer()
                    Text("Type to search across all boards and notes")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if !cardResults.isEmpty {
                            Text("CARDS (\(cardResults.count))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.textMuted)
                                .tracking(1)
                                .padding(.top, 12)

                            ForEach(cardResults, id: \.id) { card in
                                cardResultRow(card)
                            }
                        }

                        if !noteResults.isEmpty {
                            Text("NOTES (\(noteResults.count))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.textMuted)
                                .tracking(1)
                                .padding(.top, 8)

                            ForEach(noteResults, id: \.id) { note in
                                noteResultRow(note)
                            }
                        }

                        if cardResults.isEmpty && noteResults.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.textMuted)
                                Text("No results for \"\(searchText)\"")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }

    @ViewBuilder
    private func cardResultRow(_ card: Card) -> some View {
        Button(action: {
            if let boardId = card.column?.board?.id {
                selectedBoardId = boardId
                selectedNoteId = nil
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title ?? "Untitled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    HStack(spacing: 4) {
                        Text(card.column?.name ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                        Text("in")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        Text(card.column?.board?.name ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
                if card.isArchived {
                    Text("archived")
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(AppTheme.surface)
                        .clipShape(Capsule())
                }
            }
            .padding(8)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func noteResultRow(_ note: Note) -> some View {
        Button(action: {
            selectedNoteId = note.id
            selectedBoardId = nil
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title ?? "Untitled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(note.folder?.name ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
            }
            .padding(8)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            cardResults = []
            noteResults = []
            return
        }

        // Search cards
        let cardRequest = NSFetchRequest<Card>(entityName: "Card")
        cardRequest.predicate = NSPredicate(
            format: "title CONTAINS[cd] %@ OR cardDescription CONTAINS[cd] %@", trimmed, trimmed
        )
        cardRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        cardRequest.fetchLimit = 50
        cardResults = (try? viewContext.fetch(cardRequest)) ?? []

        // Search notes
        let noteRequest = NSFetchRequest<Note>(entityName: "Note")
        noteRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", trimmed)
        noteRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        noteRequest.fetchLimit = 20
        noteResults = (try? viewContext.fetch(noteRequest)) ?? []
    }
}
