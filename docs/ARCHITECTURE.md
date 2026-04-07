# Worksy — Architecture & Design Document

## Overview

Worksy is a native macOS application that combines kanban board project management with a rich-text notebook system. It's built entirely in SwiftUI with Core Data persistence, packaged as a Swift Package (no Xcode project file).

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      WorksyApp                          │
│                  (App Entry Point)                       │
├──────────────────────┬──────────────────────────────────┤
│    ContentView       │    NavigationSplitView           │
│  ┌────────────┐      │  ┌────────────────────────────┐  │
│  │ SidebarView│◄─────┼──┤ Detail View (conditional)  │  │
│  │            │      │  │  ├─ KanbanBoardView         │  │
│  │ • Boards   │      │  │  ├─ NoteEditorView          │  │
│  │ • Folders  │      │  │  ├─ SearchView              │  │
│  │ • Notes    │      │  │  └─ WelcomeView             │  │
│  └────────────┘      │  └────────────────────────────┘  │
├──────────────────────┴──────────────────────────────────┤
│                   Services Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │AuditService │  │DataMigration │  │ExportService  │  │
│  │  (singleton)│  │   Service    │  │  (Markdown/   │  │
│  │             │  │              │  │    CSV)       │  │
│  └──────┬──────┘  └──────┬───────┘  └───────────────┘  │
├─────────┼────────────────┼──────────────────────────────┤
│         │    Persistence Layer                           │
│  ┌──────▼──────────────────────────────────────────┐    │
│  │         PersistenceController                    │    │
│  │  ┌──────────────────────────────────────────┐   │    │
│  │  │     CoreDataModel (Programmatic)         │   │    │
│  │  │  Board ←→ BoardColumn ←→ Card            │   │    │
│  │  │  Folder ←→ Note                          │   │    │
│  │  │  Folder ←→ Folder (parent/children)      │   │    │
│  │  │  AuditLog                                │   │    │
│  │  └──────────────────────────────────────────┘   │    │
│  │         NSPersistentContainer (SQLite)           │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Core Data Model

### Entity Relationship Diagram

```
Board ──────────< BoardColumn ──────────< Card
  │                   │                     │
  │ name              │ name                │ title
  │ color             │ sortOrder           │ description
  │ backgroundImage   │ wipLimit            │ labels (CSV)
  │ sortOrder         │                     │ dueDate
  │ createdAt         │                     │ isArchived
  │                   │                     │ isPinned
  │                   │                     │ sortOrder
  │                   │                     │ createdAt
  │                   │                     │ updatedAt

Folder ◄───────────── Folder (parent/children, self-referencing)
  │
  │ name
  │ sortOrder
  │
  └────────< Note
               │ title
               │ content (NSAttributedString archived as Data)
               │ createdAt
               │ updatedAt

AuditLog (standalone)
  │ action (created/updated/moved/deleted)
  │ entityType
  │ entityId
  │ field, oldValue, newValue
  │ details (JSON string)
  │ timestamp
```

### Cascade Rules

| Relationship | Delete Rule | Effect |
|---|---|---|
| Board → BoardColumn | Cascade | Deleting a board deletes all its columns |
| BoardColumn → Card | Cascade | Deleting a column deletes all its cards |
| Card → BoardColumn | Nullify | Deleting a card doesn't affect the column |
| Folder → Note | Cascade | Deleting a folder deletes all its notes |
| Note → Folder | Nullify | Deleting a note doesn't affect the folder |
| Folder → Folder (children) | Cascade | Deleting a folder deletes all subfolders |
| Folder → Folder (parent) | Nullify | Deleting a subfolder doesn't affect the parent |

### Why Programmatic Core Data Model?

Instead of a `.xcdatamodeld` XML file, the entire `NSManagedObjectModel` is constructed in code:

1. **Version control friendly** — Pure Swift code, no XML merge conflicts
2. **Dynamic modification** — Easy to add new attributes or entities
3. **No Xcode dependency** — Works with `swift build` alone
4. **Lightweight migration** — New optional attributes migrate automatically

## View Hierarchy

```
WorksyApp
└── WindowGroup
    └── ContentView (NavigationSplitView)
        ├── Sidebar: SidebarView
        │   ├── Board rows (with context menu: rename, delete)
        │   └── Folder disclosure groups
        │       └── Note rows (with context menu: rename, delete)
        │
        └── Detail (conditional):
            ├── KanbanBoardView (when board selected)
            │   ├── backgroundLayer (image or solid color)
            │   ├── boardHeader (title, export, stats, archive, shuffle, bg picker)
            │   ├── ColumnView[] (horizontal scroll)
            │   │   ├── Column header (name, card count, WIP indicator)
            │   │   └── CardView[] (vertical list)
            │   │       ├── Card title, labels, due date, pin icon
            │   │       └── Context menu (edit, history, pin, archive, delete)
            │   └── addColumnButton
            │
            ├── NoteEditorView (when note selected)
            │   ├── Title text field
            │   ├── EditorToolbar (B, I, U, H1-H3, lists, code)
            │   └── RichTextEditor (NSTextView wrapper)
            │
            ├── SearchView (when search active)
            │   ├── Search text field
            │   ├── Card results (with board/column context)
            │   └── Note results (with folder context)
            │
            └── WelcomeView (default)
                ├── App icon
                └── Keyboard shortcuts
```

## Kanban Features Deep Dive

### Card Labels
Labels are stored as a comma-separated string (`"urgent,blocked"`) on the Card entity. The `labelArray` computed property converts to/from `[String]`. There are 8 preset labels with fixed colors defined in `LabelPickerView`. Labels display as color-coded badges using a custom `FlowLayout`.

### WIP Limits
Each column has an optional `wipLimit` (Int16). When `activeCards.count > wipLimit` (and wipLimit > 0), the column header shows a red indicator and the bar chart in BoardStatsView turns red.

### Background System
Three tiers of background images:
1. **Bundled** — 8 JPGs in `Resources/Backgrounds/`, loaded synchronously
2. **Internet** — 12 curated Unsplash URLs, downloaded on-demand to App Support
3. **Custom** — User picks from file system or pastes a URL

Downloaded images are saved to `~/Library/Application Support/Worksy/Backgrounds/`. The board stores just the identifier (filename for bundled, full path for custom).

### Drag & Drop
- Cards are `.draggable()` with their UUID string as the transfer type
- Columns accept `.dropDestination(for: String.self)` to receive cards
- Column-level drop also supports column reordering

### Export
`ExportService` generates Markdown or CSV representations of an entire board. Uses `NSSavePanel` for file selection.

## Data Migration

On first launch (when no boards exist), `DataMigrationService` reads `~/Desktop/Sublime Notes/action_items_new` and:
1. Parses section headers (ALL CAPS lines) into kanban columns
2. Parses `- ` prefixed lines into cards
3. Maps specific sections to notebook notes with rich text content
4. Creates a "Work Tracker" board with 12 columns and a "Imported from Sublime" folder with 6 notes

If notes are accidentally deleted, `reimportNotesIfNeeded` re-imports them on next launch.

## Audit System

`AuditService` is a singleton that logs every CRUD operation:
- `logCreate` — entity created
- `logUpdate` — field changed (old value → new value)
- `logMove` — card moved between columns
- `logDelete` — entity deleted

The `ActivityFeedView` displays these as a color-coded timeline (green=created, amber=updated, violet=moved, coral=deleted).

## Theme System

`AppTheme` provides:
- Dark-first color palette (background, surface, card, sidebar)
- Text hierarchy (primary, secondary, muted)
- 8 accent colors (amber, coral, emerald, hot pink, violet, teal, electric blue, indigo)
- `Color(hex:)` extension for hex color strings
- `accentColor(for:)` maps hex strings to SwiftUI Colors

## Build & Distribution

```bash
# Development build
swift build

# Release build
swift build -c release

# The binary at .build/release/Worksy can be placed in a .app bundle
```

The `.app` bundle at `build/Worksy.app/` contains:
- `Contents/MacOS/Worksy` — the executable
- `Contents/Info.plist` — app metadata
- `Contents/Resources/` — resource bundles with background images
