import SwiftUI
import CoreData

struct ActivityFeedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var logs: [AuditLog] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(AppTheme.textMuted)
                Text("Activity Feed")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }

            if logs.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No activity yet")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(logs, id: \.id) { log in
                            activityRow(log)
                            if log.id != logs.last?.id {
                                Divider().background(AppTheme.textMuted.opacity(0.15)).padding(.leading, 36)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 500, height: 550)
        .background(AppTheme.background)
        .onAppear { loadLogs() }
    }

    @ViewBuilder
    private func activityRow(_ log: AuditLog) -> some View {
        HStack(alignment: .top, spacing: 10) {
            actionIcon(log.action ?? "")
                .font(.system(size: 10))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(actionColor(log.action ?? ""))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(log.action?.capitalized ?? "")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(log.entityType ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Text(describeLog(log))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
                    .lineLimit(2)

                if let ts = log.timestamp {
                    Text(ts, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func describeLog(_ log: AuditLog) -> String {
        guard let json = log.details,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ""
        }

        switch log.action {
        case "created":
            return dict["name"] as? String ?? dict["title"] as? String ?? ""
        case "updated":
            let field = dict["field"] as? String ?? ""
            let newVal = dict["newValue"] as? String ?? ""
            return "\(field) changed to \(newVal)"
        case "moved":
            let from = dict["fromColumn"] as? String ?? "?"
            let to = dict["toColumn"] as? String ?? "?"
            return "\(from) -> \(to)"
        case "deleted":
            return dict["name"] as? String ?? dict["title"] as? String ?? ""
        default:
            return ""
        }
    }

    private func actionIcon(_ action: String) -> Image {
        switch action {
        case "created": return Image(systemName: "plus")
        case "updated": return Image(systemName: "pencil")
        case "moved": return Image(systemName: "arrow.right")
        case "deleted": return Image(systemName: "trash")
        default: return Image(systemName: "circle")
        }
    }

    private func actionColor(_ action: String) -> Color {
        switch action {
        case "created": return Color(hex: "#00D68F")
        case "updated": return Color(hex: "#FFB800")
        case "moved": return Color(hex: "#A855F7")
        case "deleted": return Color(hex: "#FF6B6B")
        default: return AppTheme.textMuted
        }
    }

    private func loadLogs() {
        let request = NSFetchRequest<AuditLog>(entityName: "AuditLog")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 100
        logs = (try? viewContext.fetch(request)) ?? []
    }
}
