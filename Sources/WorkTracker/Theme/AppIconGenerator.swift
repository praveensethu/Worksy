import AppKit
import SwiftUI

enum AppIconGenerator {
    /// Generates a 512x512 programmatic app icon and sets it as the dock icon.
    static func setAppIcon() {
        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size, flipped: false) { rect in
            // Dark background with rounded corners
            let bgColor = NSColor(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x2E / 255.0, alpha: 1.0)
            let bgPath = NSBezierPath(roundedRect: rect, xRadius: 90, yRadius: 90)
            bgColor.setFill()
            bgPath.fill()

            // Subtle radial gradient overlay for depth
            let gradient = NSGradient(
                colorsAndLocations:
                    (NSColor.white.withAlphaComponent(0.06), 0.0),
                    (NSColor.clear, 1.0)
            )
            gradient?.draw(in: bgPath, relativeCenterPosition: NSPoint(x: -0.2, y: 0.3))

            // Three kanban column bars
            let barWidth: CGFloat = 100
            let barSpacing: CGFloat = 30
            let totalWidth = barWidth * 3 + barSpacing * 2
            let startX = (rect.width - totalWidth) / 2

            let barConfigs: [(color: NSColor, height: CGFloat, yOffset: CGFloat)] = [
                // Electric Blue - left bar (tallest)
                (NSColor(red: 0x0F / 255.0, green: 0x9B / 255.0, blue: 0xF7 / 255.0, alpha: 1.0), 240, 160),
                // Hot Pink - center bar (medium)
                (NSColor(red: 0xFF / 255.0, green: 0x2D / 255.0, blue: 0x78 / 255.0, alpha: 1.0), 200, 180),
                // Emerald - right bar (shorter)
                (NSColor(red: 0x00 / 255.0, green: 0xD6 / 255.0, blue: 0x8F / 255.0, alpha: 1.0), 160, 200),
            ]

            for (index, config) in barConfigs.enumerated() {
                let x = startX + CGFloat(index) * (barWidth + barSpacing)
                let barRect = NSRect(x: x, y: config.yOffset, width: barWidth, height: config.height)
                let barPath = NSBezierPath(roundedRect: barRect, xRadius: 14, yRadius: 14)

                // Bar fill
                config.color.setFill()
                barPath.fill()

                // Subtle inner highlight
                let highlightColor = config.color.blended(withFraction: 0.25, of: NSColor.white) ?? config.color
                let highlightRect = NSRect(x: x + 8, y: config.yOffset + config.height - 50, width: barWidth - 16, height: 30)
                let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: 6, yRadius: 6)
                highlightColor.withAlphaComponent(0.3).setFill()
                highlightPath.fill()

                // Small "card" rectangles on each bar
                let cardColor = NSColor.white.withAlphaComponent(0.2)
                let cardCount = 3 - index
                for cardIdx in 0..<cardCount {
                    let cardY = config.yOffset + 20 + CGFloat(cardIdx) * 40
                    let cardRect = NSRect(x: x + 12, y: cardY, width: barWidth - 24, height: 28)
                    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 5, yRadius: 5)
                    cardColor.setFill()
                    cardPath.fill()
                }
            }

            // Small notebook/page icon in bottom-right
            let pageRect = NSRect(x: 370, y: 60, width: 70, height: 85)
            let pagePath = NSBezierPath(roundedRect: pageRect, xRadius: 8, yRadius: 8)
            NSColor.white.withAlphaComponent(0.85).setFill()
            pagePath.fill()

            // Lines on the page
            let lineColor = NSColor(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x2E / 255.0, alpha: 0.3)
            lineColor.setStroke()
            for i in 0..<4 {
                let lineY = pageRect.minY + 15 + CGFloat(i) * 16
                let linePath = NSBezierPath()
                linePath.move(to: NSPoint(x: pageRect.minX + 10, y: lineY))
                linePath.line(to: NSPoint(x: pageRect.maxX - 10, y: lineY))
                linePath.lineWidth = 2
                linePath.stroke()
            }

            // Dog-ear on page
            let earSize: CGFloat = 16
            let earPath = NSBezierPath()
            earPath.move(to: NSPoint(x: pageRect.maxX - earSize, y: pageRect.maxY))
            earPath.line(to: NSPoint(x: pageRect.maxX, y: pageRect.maxY - earSize))
            earPath.line(to: NSPoint(x: pageRect.maxX - earSize, y: pageRect.maxY - earSize))
            earPath.close()
            NSColor(red: 0xD0 / 255.0, green: 0xD0 / 255.0, blue: 0xD8 / 255.0, alpha: 1.0).setFill()
            earPath.fill()

            // "WT" text at the bottom center
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            ]
            let wtString = NSAttributedString(string: "WT", attributes: textAttributes)
            let textSize = wtString.size()
            let textOrigin = NSPoint(
                x: (rect.width - textSize.width) / 2 - 30,
                y: 65
            )
            wtString.draw(at: textOrigin)

            return true
        }

        NSApplication.shared.applicationIconImage = image
    }
}
