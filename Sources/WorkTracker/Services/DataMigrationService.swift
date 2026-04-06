import CoreData
import AppKit

enum DataMigrationService {

    private static let sublimeFilePath = NSString("~/Desktop/Sublime Notes/action_items_new").expandingTildeInPath

    // MARK: - Section mapping for Kanban columns

    private static let kanbanSections: [(header: String, columnName: String)] = [
        ("CURRENTLY IN PROGRESS", "CURRENTLY IN PROGRESS"),
        ("ADDITIONAL", "ADDITIONAL"),
        ("COMPLETED", "COMPLETED"),
        ("THINGS TO FOLLOW UP FROM TODAY", "THINGS TO FOLLOW UP FROM TODAY"),
        ("NEXT SPRINT", "NEXT SPRINT"),
        ("SIDE PROJECTS", "SIDE PROJECTS"),
        ("KTLO ITEMS", "KTLO ITEMS"),
        ("TRIAGED", "TRIAGED"),
        ("PROD CHANGES TO SYNC", "PROD CHANGES TO SYNC"),
        ("ON HOLD CANNOT BE WORKED ON", "ON HOLD"),
        ("KTLO ITEMS PICKED UP IN THIS SPRINT", "KTLO PICKED UP THIS SPRINT"),
        ("SUPERVISING", "SUPERVISING"),
    ]

    // Headers that map to notebook notes (non-kanban sections)
    private static let notebookSections: [String: String] = [
        "IMPORTANT LINKS": "Important Links",
        "DIFFERENT TEAMS": "Different Teams",
        "FEB,MAR,APR 2026": "Sprint History",
        "BETTER ENGINEERING METRICS TRACKER": "Engineering Metrics",
        "CLAUDE CODE - TOKEN CONSUMPTION": "Claude Code Token Consumption",
        "DIFFERENT IDEAS I CAN USE TO BUILD USING AI": "Ideas",
    ]

    // All known section headers (uppercased) for matching
    private static var allSectionHeaders: Set<String> {
        var headers = Set<String>()
        for (header, _) in kanbanSections {
            headers.insert(header)
        }
        for key in notebookSections.keys {
            headers.insert(key)
        }
        return headers
    }

    // MARK: - Public API

    static func importFromSublime(context: NSManagedObjectContext) {
        guard FileManager.default.fileExists(atPath: sublimeFilePath) else {
            print("[DataMigrationService] Source file not found at \(sublimeFilePath). Skipping import.")
            return
        }

        guard let fileContents = try? String(contentsOfFile: sublimeFilePath, encoding: .utf8) else {
            print("[DataMigrationService] Could not read file at \(sublimeFilePath). Skipping import.")
            return
        }

        let sections = parseSections(from: fileContents)
        createKanbanBoard(from: sections, context: context)
        createNotebooks(from: sections, context: context)

        do {
            try context.save()
            print("[DataMigrationService] Successfully imported data from Sublime Notes.")
        } catch {
            print("[DataMigrationService] Failed to save imported data: \(error)")
        }
    }

    static func shouldImport(context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Board")
        request.fetchLimit = 1
        let count = (try? context.count(for: request)) ?? 0
        return count == 0
    }

    // MARK: - Parser

    /// Each parsed section has a header (uppercased) and its raw content lines (excluding the header line itself).
    private struct ParsedSection {
        let header: String        // uppercased
        let rawHeader: String     // original casing
        let lines: [String]       // content lines (not the header)
    }

    private static func parseSections(from text: String) -> [ParsedSection] {
        let allLines = text.components(separatedBy: .newlines)
        var sections: [ParsedSection] = []
        var currentHeader: String?
        var currentRawHeader: String?
        var currentLines: [String] = []

        for line in allLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip the very first line if it's the filename header
            if trimmed == "action_items_new" { continue }

            let upper = trimmed.uppercased()
            if isSectionHeader(upper) {
                // Flush previous section
                if let header = currentHeader, let rawHeader = currentRawHeader {
                    sections.append(ParsedSection(header: header, rawHeader: rawHeader, lines: currentLines))
                }
                currentHeader = upper
                currentRawHeader = trimmed
                currentLines = []
            } else {
                currentLines.append(trimmed)
            }
        }

        // Flush last section
        if let header = currentHeader, let rawHeader = currentRawHeader {
            sections.append(ParsedSection(header: header, rawHeader: rawHeader, lines: currentLines))
        }

        return sections
    }

    private static func isSectionHeader(_ uppercasedLine: String) -> Bool {
        if uppercasedLine.isEmpty { return false }

        // Direct match against known headers
        if allSectionHeaders.contains(uppercasedLine) { return true }

        // Fuzzy match for some headers that differ slightly in the file
        // "Things to follow up from today" is mixed case in the file
        if uppercasedLine == "THINGS TO FOLLOW UP FROM TODAY" { return true }
        // "KTLO items" in file vs "KTLO ITEMS" in our mapping
        if uppercasedLine == "KTLO ITEMS" { return true }
        // "KTLO items picked up in this sprint"
        if uppercasedLine == "KTLO ITEMS PICKED UP IN THIS SPRINT" { return true }

        return false
    }

    // MARK: - Kanban Board Creation

    private static func createKanbanBoard(from sections: [ParsedSection], context: NSManagedObjectContext) {
        let board = Board(context: context, name: "Work Tracker")

        // Map from uppercased header → parsed section for quick lookup
        var sectionMap: [String: ParsedSection] = [:]
        for section in sections {
            sectionMap[section.header] = section
        }

        for (index, mapping) in kanbanSections.enumerated() {
            let column = BoardColumn(context: context, name: mapping.columnName, board: board)
            column.sortOrder = Int16(index)

            if let section = sectionMap[mapping.header] {
                createCards(from: section.lines, in: column, context: context)
            }
        }
    }

    private static func createCards(from lines: [String], in column: BoardColumn, context: NSManagedObjectContext) {
        var cardIndex: Int16 = 0
        for line in lines {
            guard line.hasPrefix("- ") else { continue }

            let itemText = String(line.dropFirst(2)) // Remove "- "

            // Check if there's a status suffix like " - IN PROGRESS" or " - COMPLETED"
            let (title, status) = extractTitleAndStatus(from: itemText)

            let card = Card(context: context, title: title, column: column)
            card.sortOrder = cardIndex
            if let status = status {
                card.cardDescription = status
            }
            cardIndex += 1
        }
    }

    private static func extractTitleAndStatus(from text: String) -> (title: String, status: String?) {
        // Known status suffixes
        let statuses = ["IN PROGRESS", "COMPLETED", "MONTHLY REVIEW", "ON HOLD", "BLOCKED", "TODO", "DONE"]

        // Look for " - STATUS" at the end
        for status in statuses {
            let suffix = " - \(status)"
            if text.uppercased().hasSuffix(suffix) {
                let titleEnd = text.index(text.endIndex, offsetBy: -suffix.count)
                let title = String(text[text.startIndex..<titleEnd])
                return (title, status)
            }
        }

        return (text, nil)
    }

    // MARK: - Notebook Creation

    private static func createNotebooks(from sections: [ParsedSection], context: NSManagedObjectContext) {
        let folder = Folder(context: context, name: "Imported from Sublime")

        var sectionMap: [String: ParsedSection] = [:]
        for section in sections {
            sectionMap[section.header] = section
        }

        var noteIndex: Int16 = 0

        for (sectionHeader, noteTitle) in notebookSections.sorted(by: { $0.value < $1.value }) {
            if let section = sectionMap[sectionHeader] {
                let contentText = section.lines
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")

                let note = Note(context: context, title: noteTitle, folder: folder)
                note.content = createAttributedStringData(from: contentText)
                noteIndex += 1
            } else {
                // Create empty note for sections not found in the file
                let note = Note(context: context, title: noteTitle, folder: folder)
                note.content = createAttributedStringData(from: "(No content found)")
                noteIndex += 1
            }
        }
    }

    private static func createAttributedStringData(from text: String) -> Data? {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 14),
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)

        return try? NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: false)
    }
}
