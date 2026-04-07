import AppKit
import CoreData

enum ExportService {

    static func exportAsMarkdown(board: Board) -> String {
        var md = "# \(board.name ?? "Untitled Board")\n\n"
        let columns = (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }

        for col in columns {
            let cards = col.activeCards.sorted { $0.sortOrder < $1.sortOrder }
            md += "## \(col.name ?? "Untitled")"
            if col.wipLimit > 0 {
                md += " (WIP: \(col.wipLimit))"
            }
            md += "\n\n"

            if cards.isEmpty {
                md += "_No cards_\n\n"
            } else {
                for card in cards {
                    let labels = card.labelArray
                    let labelStr = labels.isEmpty ? "" : " `\(labels.joined(separator: "` `"))`"
                    let pinStr = card.isPinned ? " [pinned]" : ""
                    let dueStr: String
                    if let due = card.dueDate {
                        let f = DateFormatter()
                        f.dateStyle = .short
                        dueStr = " (due: \(f.string(from: due)))"
                    } else {
                        dueStr = ""
                    }
                    md += "- **\(card.title ?? "Untitled")**\(pinStr)\(dueStr)\(labelStr)\n"
                    if let desc = card.cardDescription, !desc.isEmpty {
                        md += "  \(desc.replacingOccurrences(of: "\n", with: "\n  "))\n"
                    }
                }
                md += "\n"
            }
        }

        return md
    }

    static func exportAsCSV(board: Board) -> String {
        var csv = "Column,Title,Description,Labels,Due Date,Pinned,Archived\n"
        let columns = (board.columns?.allObjects as? [BoardColumn] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }

        for col in columns {
            let allCards = (col.cards?.allObjects as? [Card] ?? [])
                .sorted { $0.sortOrder < $1.sortOrder }
            for card in allCards {
                let title = (card.title ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                let desc = (card.cardDescription ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                let labels = card.labelArray.joined(separator: ";")
                let due = card.dueDate.map { ISO8601DateFormatter().string(from: $0) } ?? ""
                csv += "\"\(col.name ?? "")\",\"\(title)\",\"\(desc)\",\"\(labels)\",\"\(due)\",\(card.isPinned),\(card.isArchived)\n"
            }
        }

        return csv
    }

    static func saveToFile(content: String, defaultName: String, fileType: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = fileType == "csv"
            ? [.commaSeparatedText]
            : [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
