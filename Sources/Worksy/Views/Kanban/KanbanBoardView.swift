import SwiftUI
import AppKit
import CoreData

struct KanbanBoardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var board: Board

    @State private var showDeleteColumnConfirmation = false
    @State private var showBackgroundPicker = false
    @State private var showStats = false
    @State private var showArchive = false
    @State private var cachedBackgroundImage: NSImage?

    private var accentColor: Color {
        AppTheme.accentColor(for: board.color ?? "#FFB800")
    }

    private var sortedColumns: [BoardColumn] {
        (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack {
            // Background: image or solid color
            backgroundLayer

            VStack(alignment: .leading, spacing: 0) {
                // Board header with gradient
                boardHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [accentColor.opacity(0.08), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Columns horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(sortedColumns, id: \.id) { column in
                            ColumnView(column: column, accentColor: accentColor)
                                .dropDestination(for: String.self) { items, _ in
                                    guard let id = items.first else { return false }
                                    // Column reorder: prefixed with "col:"
                                    if id.hasPrefix("col:"),
                                       let draggedId = UUID(uuidString: String(id.dropFirst(4))) {
                                        return handleColumnReorder(draggedColumnId: draggedId, targetColumn: column)
                                    }
                                    return false
                                } isTargeted: { _ in }
                        }

                        addColumnButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .animation(.easeInOut(duration: 0.3), value: sortedColumns.map(\.id))
                }
            }
        }
        .clipped()
        .onAppear { loadBackgroundAsync() }
        .onChange(of: board.backgroundImage) { _ in loadBackgroundAsync() }
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if let nsImage = cachedBackgroundImage {
            ZStack {
                GeometryReader { geo in
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }

                // Light overlay for readability
                Color.black.opacity(0.3)
            }
        } else {
            AppTheme.background
        }
    }

    private func loadBackgroundAsync() {
        guard let identifier = board.backgroundImage, !identifier.isEmpty else {
            cachedBackgroundImage = nil
            return
        }

        // Bundled images are small — load synchronously to avoid flash
        if !identifier.contains("/") {
            cachedBackgroundImage = loadBackgroundImage(identifier)
            return
        }

        // Custom user images — load async
        DispatchQueue.global(qos: .userInitiated).async {
            let image = loadBackgroundImage(identifier)
            DispatchQueue.main.async {
                cachedBackgroundImage = image
            }
        }
    }

    private func loadBackgroundImage(_ identifier: String) -> NSImage? {
        if !identifier.contains("/") {
            let name = identifier.replacingOccurrences(of: ".jpg", with: "")
                .replacingOccurrences(of: ".png", with: "")
                .replacingOccurrences(of: ".jpeg", with: "")
            let ext = (identifier as NSString).pathExtension

            // Try Bundle.module first (Swift Package resources)
            if let url = Bundle.module.url(forResource: name, withExtension: ext.isEmpty ? "jpg" : ext, subdirectory: "Backgrounds") {
                return NSImage(contentsOf: url)
            }

            // Fallback: search in main bundle
            if let url = Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? "jpg" : ext, subdirectory: "Backgrounds") {
                return NSImage(contentsOf: url)
            }

            // Fallback: search resource bundle by name
            if let bundleURL = Bundle.main.url(forResource: "WorkTracker_WorkTracker", withExtension: "bundle"),
               let resBundle = Bundle(url: bundleURL),
               let url = resBundle.url(forResource: name, withExtension: ext.isEmpty ? "jpg" : ext, subdirectory: "Backgrounds") {
                return NSImage(contentsOf: url)
            }
        }
        return NSImage(contentsOfFile: identifier)
    }

    // MARK: - Board Header

    @ViewBuilder
    private var boardHeader: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accentColor)
                .frame(width: 12, height: 12)

            Text(board.name ?? "Untitled Board")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            Text("\(sortedColumns.count) columns")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            Spacer()

            // Export
            Menu {
                Button("Export as Markdown") {
                    let md = ExportService.exportAsMarkdown(board: board)
                    ExportService.saveToFile(content: md, defaultName: "\(board.name ?? "board").md", fileType: "md")
                }
                Button("Export as CSV") {
                    let csv = ExportService.exportAsCSV(board: board)
                    ExportService.saveToFile(content: csv, defaultName: "\(board.name ?? "board").csv", fileType: "csv")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Export board")

            // Stats
            Button(action: { showStats.toggle() }) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Board stats")
            .popover(isPresented: $showStats, arrowEdge: .bottom) {
                BoardStatsView(board: board)
            }

            // Archive
            Button(action: { showArchive.toggle() }) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Archived cards")
            .popover(isPresented: $showArchive, arrowEdge: .bottom) {
                ArchiveView(board: board)
                    .environment(\.managedObjectContext, viewContext)
            }

            // Shuffle background
            Button(action: { shuffleBackground() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Random background")

            // Background picker
            Button(action: { showBackgroundPicker.toggle() }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showBackgroundPicker, arrowEdge: .bottom) {
                BackgroundPickerView(board: board)
                    .environment(\.managedObjectContext, viewContext)
            }

        }
    }

    // MARK: - Add Column Button

    @ViewBuilder
    private var addColumnButton: some View {
        Button(action: { addColumn() }) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                Text("Add Column")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
            .frame(width: 280, height: 100)
            .background(AppTheme.card.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(AppTheme.textMuted.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CRUD Operations

    private func shuffleBackground() {
        let allImages = BackgroundPickerView.bundledImages
        let current = board.backgroundImage ?? ""
        var candidates = allImages.filter { $0 != current }
        if candidates.isEmpty { candidates = allImages }
        board.backgroundImage = candidates.randomElement()
        try? viewContext.save()
    }

    private func addColumn() {
        let existingColumns = sortedColumns
        let nextOrder = (existingColumns.last.map { Int($0.sortOrder) } ?? -1) + 1

        let column = BoardColumn(context: viewContext, name: "New Column", board: board)
        column.sortOrder = Int16(nextOrder)

        AuditService.shared.logCreate(
            entityType: "BoardColumn",
            entityId: column.id!,
            details: ["name": "New Column", "board": board.name ?? "Unknown"],
            context: viewContext
        )

        try? viewContext.save()
    }

    private func handleColumnReorder(draggedColumnId: UUID, targetColumn: BoardColumn) -> Bool {
        guard draggedColumnId != targetColumn.id else { return false }
        let request = NSFetchRequest<BoardColumn>(entityName: "BoardColumn")
        request.predicate = NSPredicate(format: "id == %@ AND board == %@", draggedColumnId as CVarArg, board)
        request.fetchLimit = 1
        guard let draggedCol = try? viewContext.fetch(request).first else { return false }

        var cols = sortedColumns
        cols.removeAll { $0.id == draggedCol.id }
        if let targetIdx = cols.firstIndex(where: { $0.id == targetColumn.id }) {
            cols.insert(draggedCol, at: targetIdx)
        } else {
            cols.append(draggedCol)
        }
        for (i, c) in cols.enumerated() { c.sortOrder = Int16(i) }
        try? viewContext.save()
        return true
    }
}
