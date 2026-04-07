import SwiftUI
import CoreData

struct BoardTemplate {
    let name: String
    let icon: String
    let columns: [String]
    let color: String

    static let templates: [BoardTemplate] = [
        BoardTemplate(
            name: "Sprint Board",
            icon: "figure.run",
            columns: ["Backlog", "To Do", "In Progress", "In Review", "Done"],
            color: "#FFB800"
        ),
        BoardTemplate(
            name: "Personal Kanban",
            icon: "person.fill",
            columns: ["To Do", "Doing", "Done"],
            color: "#00D68F"
        ),
        BoardTemplate(
            name: "Bug Tracker",
            icon: "ladybug.fill",
            columns: ["Reported", "Triaged", "In Progress", "Fixed", "Verified"],
            color: "#FF6B6B"
        ),
        BoardTemplate(
            name: "Feature Pipeline",
            icon: "lightbulb.fill",
            columns: ["Ideas", "Research", "Design", "Development", "Testing", "Shipped"],
            color: "#A855F7"
        ),
        BoardTemplate(
            name: "Weekly Planner",
            icon: "calendar",
            columns: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
            color: "#14B8A6"
        ),
    ]
}

struct BoardTemplatePickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBoardId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create from Template")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(BoardTemplate.templates, id: \.name) { template in
                        Button(action: { createFromTemplate(template) }) {
                            HStack(spacing: 12) {
                                Image(systemName: template.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: template.color))
                                    .frame(width: 36, height: 36)
                                    .background(Color(hex: template.color).opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(template.columns.joined(separator: " -> "))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textMuted)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 420, height: 380)
        .background(AppTheme.background)
    }

    private func createFromTemplate(_ template: BoardTemplate) {
        let board = Board(context: viewContext, name: template.name, color: template.color)
        let boardCount = (try? viewContext.count(for: NSFetchRequest<Board>(entityName: "Board"))) ?? 0
        board.sortOrder = Int16(boardCount)

        for (index, colName) in template.columns.enumerated() {
            let col = BoardColumn(context: viewContext, name: colName, board: board)
            col.sortOrder = Int16(index)
        }

        AuditService.shared.logCreate(
            entityType: "Board",
            entityId: board.id!,
            details: ["name": template.name, "template": template.name],
            context: viewContext
        )

        try? viewContext.save()
        selectedBoardId = board.id
        dismiss()
    }
}
