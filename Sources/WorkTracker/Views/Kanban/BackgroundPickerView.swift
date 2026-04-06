import SwiftUI
import AppKit
import CoreData

struct BackgroundPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var board: Board

    private let bundledImages = [
        "mountain.jpg", "forest.jpg", "ocean.jpg", "aurora.jpg",
        "sunset.jpg", "lake.jpg", "stars.jpg", "waterfall.jpg"
    ]

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Board Background")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    // None option (solid color)
                    noneOption

                    // Bundled images
                    ForEach(bundledImages, id: \.self) { filename in
                        bundledImageThumbnail(filename)
                    }

                    // Custom images from app support directory
                    ForEach(customImagePaths(), id: \.self) { path in
                        customImageThumbnail(path)
                    }

                    // Add Custom button
                    addCustomButton
                }
            }
        }
        .padding(16)
        .frame(width: 340, height: 360)
        .background(AppTheme.background)
    }

    // MARK: - None Option

    @ViewBuilder
    private var noneOption: some View {
        let isSelected = board.backgroundImage == nil || board.backgroundImage?.isEmpty == true
        Button(action: {
            board.backgroundImage = nil
            try? viewContext.save()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.surface)
                    .frame(height: 70)

                VStack(spacing: 4) {
                    Image(systemName: "rectangle.slash")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textMuted)
                    Text("None")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#00D68F") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bundled Image Thumbnail

    @ViewBuilder
    private func bundledImageThumbnail(_ filename: String) -> some View {
        let isSelected = board.backgroundImage == filename
        Button(action: {
            board.backgroundImage = filename
            try? viewContext.save()
        }) {
            ZStack {
                if let url = Bundle.module.url(forResource: filename.replacingOccurrences(of: ".jpg", with: ""),
                                                withExtension: "jpg",
                                                subdirectory: "Backgrounds"),
                   let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 70)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.surface)
                        .frame(height: 70)
                        .overlay(
                            Text(filename.replacingOccurrences(of: ".jpg", with: "").capitalized)
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.textMuted)
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#00D68F") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Image Thumbnail

    @ViewBuilder
    private func customImageThumbnail(_ path: String) -> some View {
        let isSelected = board.backgroundImage == path
        Button(action: {
            board.backgroundImage = path
            try? viewContext.save()
        }) {
            ZStack {
                if let nsImage = NSImage(contentsOfFile: path) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 70)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.surface)
                        .frame(height: 70)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#00D68F") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Custom Button

    @ViewBuilder
    private var addCustomButton: some View {
        Button(action: { pickCustomImage() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.surface)
                    .frame(height: 70)

                VStack(spacing: 4) {
                    Image(systemName: "plus.rectangle.on.folder")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Add Custom...")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(AppTheme.textMuted.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - File Picker

    private func pickCustomImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Background Image"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }

        let destDir = customBackgroundsDirectory()
        let destURL = destDir.appendingPathComponent(sourceURL.lastPathComponent)

        do {
            if !FileManager.default.fileExists(atPath: destDir.path) {
                try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            }
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            board.backgroundImage = destURL.path
            try? viewContext.save()
        } catch {
            print("[BackgroundPicker] Failed to copy image: \(error)")
        }
    }

    // MARK: - Custom Image Paths

    private func customImagePaths() -> [String] {
        let dir = customBackgroundsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        return files
            .filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".png") || $0.hasSuffix(".heic") }
            .map { dir.appendingPathComponent($0).path }
    }

    private func customBackgroundsDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("WorkTracker/Backgrounds")
    }
}
