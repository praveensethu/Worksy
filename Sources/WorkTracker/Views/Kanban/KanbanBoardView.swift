import SwiftUI
import CoreData

struct KanbanBoardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var board: Board

    @State private var showDeleteColumnConfirmation = false

    private var accentColor: Color {
        AppTheme.accentColor(for: board.color ?? "#007AFF")
    }

    private var sortedColumns: [BoardColumn] {
        (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Board header with gradient
                boardHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [accentColor.opacity(0.12), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )

                // Columns horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(sortedColumns, id: \.id) { column in
                            ColumnView(column: column, accentColor: accentColor)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }

                        // Add Column button
                        addColumnButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .animation(.easeInOut(duration: 0.3), value: sortedColumns.map(\.id))
                }
            }
        }
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

            Text("\(sortedColumns.count) columns")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)

            Spacer()
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
}
