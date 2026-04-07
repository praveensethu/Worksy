import SwiftUI

struct LabelConfig {
    let name: String
    let color: String

    static let presets: [LabelConfig] = [
        LabelConfig(name: "urgent", color: "#FF3B30"),
        LabelConfig(name: "blocked", color: "#FF6B6B"),
        LabelConfig(name: "review", color: "#A855F7"),
        LabelConfig(name: "bug", color: "#FF2D78"),
        LabelConfig(name: "feature", color: "#00D68F"),
        LabelConfig(name: "improvement", color: "#14B8A6"),
        LabelConfig(name: "research", color: "#FFB800"),
        LabelConfig(name: "tech-debt", color: "#6366F1"),
    ]

    static func color(for label: String) -> Color {
        if let preset = presets.first(where: { $0.name == label }) {
            return Color(hex: preset.color)
        }
        return Color(hex: "#8B8DA3")
    }
}

struct LabelPickerView: View {
    @Binding var selectedLabels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LABELS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1)

            FlowLayout(spacing: 6) {
                ForEach(LabelConfig.presets, id: \.name) { preset in
                    let isSelected = selectedLabels.contains(preset.name)
                    Button(action: {
                        if isSelected {
                            selectedLabels.removeAll { $0 == preset.name }
                        } else {
                            selectedLabels.append(preset.name)
                        }
                    }) {
                        Text(preset.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isSelected ? .white : Color(hex: preset.color))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isSelected ? Color(hex: preset.color) : Color(hex: preset.color).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct LabelBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(LabelConfig.color(for: label))
            .clipShape(Capsule())
    }
}

// Simple flow layout for labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
