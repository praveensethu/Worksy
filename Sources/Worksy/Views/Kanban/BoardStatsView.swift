import SwiftUI
import CoreData

struct BoardStatsView: View {
    @ObservedObject var board: Board

    private var columns: [BoardColumn] {
        (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var totalCards: Int {
        columns.reduce(0) { $0 + $1.activeCards.count }
    }

    private var archivedCount: Int {
        columns.reduce(0) { total, col in
            total + (col.cards?.allObjects as? [Card] ?? []).filter { $0.isArchived }.count
        }
    }

    private var overdueCount: Int {
        columns.reduce(0) { total, col in
            total + col.activeCards.filter { $0.isOverdue }.count
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Board Statistics")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            // Summary cards
            HStack(spacing: 12) {
                statCard("Total Cards", value: "\(totalCards)", color: "#FFB800")
                statCard("Archived", value: "\(archivedCount)", color: "#8B8DA3")
                statCard("Overdue", value: "\(overdueCount)", color: "#FF3B30")
                statCard("Columns", value: "\(columns.count)", color: "#00D68F")
            }

            Divider().background(AppTheme.textMuted.opacity(0.3))

            // Per-column breakdown
            Text("CARDS PER COLUMN")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1)

            let maxCount = columns.map { $0.activeCards.count }.max() ?? 1

            ScrollView {
            LazyVStack(spacing: 6) {
            ForEach(columns, id: \.id) { col in
                HStack(spacing: 8) {
                    Text(col.name ?? "?")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 180, alignment: .trailing)
                        .lineLimit(1)

                    GeometryReader { geo in
                        let width = maxCount > 0 ? (CGFloat(col.activeCards.count) / CGFloat(maxCount)) * geo.size.width : 0
                        RoundedRectangle(cornerRadius: 3)
                            .fill(col.isOverWipLimit ? Color(hex: "#FF3B30") : AppTheme.accentColor(for: board.color ?? "#FFB800"))
                            .frame(width: max(width, 2), height: 16)
                    }
                    .frame(height: 16)

                    Text("\(col.activeCards.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: 24)

                    if col.wipLimit > 0 {
                        Text("/\(col.wipLimit)")
                            .font(.system(size: 10))
                            .foregroundColor(col.isOverWipLimit ? Color(hex: "#FF3B30") : AppTheme.textMuted)
                    }
                }
            }
            }
            }
        }
        .padding(20)
        .frame(width: 600, height: 500)
        .background(AppTheme.background)
    }

    @ViewBuilder
    private func statCard(_ title: String, value: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: color))
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
