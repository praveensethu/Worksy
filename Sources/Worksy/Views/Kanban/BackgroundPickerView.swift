import SwiftUI
import AppKit
import CoreData

struct BackgroundPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var board: Board

    @State private var imageURL = ""
    @State private var isDownloading = false
    @State private var downloadError = ""

    static let bundledImages = [
        "mountain.jpg", "forest.jpg", "ocean.jpg", "aurora.jpg",
        "sunset.jpg", "lake.jpg", "stars.jpg", "waterfall.jpg"
    ]

    // Curated free Unsplash images (direct download links, free to use)
    private static let onlineImages: [(name: String, url: String)] = [
        ("Cherry Blossoms", "https://images.unsplash.com/photo-1522383225653-ed111181a951?w=1920&q=80"),
        ("Northern Lights", "https://images.unsplash.com/photo-1483347756197-71ef80e95f73?w=1920&q=80"),
        ("Tropical Beach", "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1920&q=80"),
        ("Snow Mountains", "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1920&q=80"),
        ("City Skyline", "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=1920&q=80"),
        ("Autumn Forest", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1920&q=80"),
        ("Desert Dunes", "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=1920&q=80"),
        ("Galaxy", "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1920&q=80"),
        ("Lavender Field", "https://images.unsplash.com/photo-1499002238440-d264edd596ec?w=1920&q=80"),
        ("Rainforest", "https://images.unsplash.com/photo-1448375240586-882707db888b?w=1920&q=80"),
        ("Volcano", "https://images.unsplash.com/photo-1462651567147-aa679fd1cfaf?w=1920&q=80"),
        ("Coral Reef", "https://images.unsplash.com/photo-1546026423-cc4642628d2b?w=1920&q=80"),
    ]

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Board Background")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Daily rotation toggle
                Toggle(isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dailyRotate_\(board.id?.uuidString ?? "")") },
                    set: { newValue in
                        UserDefaults.standard.set(newValue, forKey: "dailyRotate_\(board.id?.uuidString ?? "")")
                        if newValue {
                            applyDailyBackground()
                        }
                    }
                )) {
                    Text("Daily")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                // Shuffle button
                Button(action: { shuffleBackground() }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Random background")
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    // None option (solid color)
                    noneOption

                    // Bundled images
                    ForEach(Self.bundledImages, id: \.self) { filename in
                        bundledImageThumbnail(filename)
                    }

                    // Custom images from app support directory
                    ForEach(customImagePaths(), id: \.self) { path in
                        customImageThumbnail(path)
                    }

                    // Add Custom button
                    addCustomButton
                }

                // Online images section
                Text("FROM INTERNET")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
                    .tracking(1)
                    .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Self.onlineImages, id: \.url) { img in
                        onlineImageThumbnail(img.name, url: img.url)
                    }
                }

                // Custom URL input
                VStack(alignment: .leading, spacing: 6) {
                    Text("PASTE IMAGE URL")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                        .tracking(1)
                        .padding(.top, 8)

                    HStack(spacing: 8) {
                        TextField("https://...", text: $imageURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))

                        Button(action: { downloadFromURL() }) {
                            if isDownloading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Download")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Color(hex: "#00D68F"))
                        .disabled(imageURL.isEmpty || isDownloading)
                    }

                    if !downloadError.isEmpty {
                        Text(downloadError)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#FF3B30"))
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 400, height: 550)
        .background(AppTheme.background)
        .onAppear {
            if UserDefaults.standard.bool(forKey: "dailyRotate_\(board.id?.uuidString ?? "")") {
                applyDailyBackground()
            }
        }
    }

    // MARK: - Daily Rotation

    private func applyDailyBackground() {
        let allImages = Self.bundledImages + customImagePaths()
        guard !allImages.isEmpty else { return }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % allImages.count
        board.backgroundImage = allImages[index]
        try? viewContext.save()
    }

    private func shuffleBackground() {
        let allImages = Self.bundledImages + customImagePaths()
        guard !allImages.isEmpty else { return }
        let current = board.backgroundImage ?? ""
        var candidates = allImages.filter { $0 != current }
        if candidates.isEmpty { candidates = allImages }
        board.backgroundImage = candidates.randomElement()
        try? viewContext.save()
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
        return appSupport.appendingPathComponent("Worksy/Backgrounds")
    }

    // MARK: - Online Image Thumbnail

    @ViewBuilder
    private func onlineImageThumbnail(_ name: String, url: String) -> some View {
        let localPath = customBackgroundsDirectory().appendingPathComponent("\(name.replacingOccurrences(of: " ", with: "_")).jpg").path
        let isDownloaded = FileManager.default.fileExists(atPath: localPath)
        let isSelected = board.backgroundImage == localPath

        Button(action: {
            if isDownloaded {
                board.backgroundImage = localPath
                try? viewContext.save()
            } else {
                downloadImage(from: url, name: name)
            }
        }) {
            ZStack {
                if isDownloaded, let nsImage = NSImage(contentsOfFile: localPath) {
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
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#00D68F"))
                                Text(name)
                                    .font(.system(size: 8))
                                    .foregroundColor(AppTheme.textMuted)
                                    .lineLimit(1)
                            }
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

    // MARK: - Download Image

    private func downloadImage(from urlString: String, name: String) {
        guard let url = URL(string: urlString) else {
            downloadError = "Invalid URL"
            return
        }

        isDownloading = true
        downloadError = ""

        let destDir = customBackgroundsDirectory()
        let destPath = destDir.appendingPathComponent("\(name.replacingOccurrences(of: " ", with: "_")).jpg")

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isDownloading = false

                if let error = error {
                    downloadError = error.localizedDescription
                    return
                }

                guard let data = data, let nsImage = NSImage(data: data), nsImage.isValid else {
                    downloadError = "Failed to download image"
                    return
                }

                do {
                    if !FileManager.default.fileExists(atPath: destDir.path) {
                        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                    }
                    try data.write(to: destPath)
                    board.backgroundImage = destPath.path
                    try? viewContext.save()
                } catch {
                    downloadError = "Failed to save: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func downloadFromURL() {
        guard !imageURL.isEmpty else { return }
        let name = "custom_\(UUID().uuidString.prefix(8))"
        downloadImage(from: imageURL, name: name)
        imageURL = ""
    }
}
