import SwiftUI
import AppKit

struct EditorToolbar: View {
    @ObservedObject var editorState: RichTextEditorState

    var body: some View {
        HStack(spacing: 4) {
            // Text formatting
            Group {
                toolbarButton(icon: "bold", tooltip: "Bold") { toggleBold() }
                toolbarButton(icon: "italic", tooltip: "Italic") { toggleItalic() }
                toolbarButton(icon: "underline", tooltip: "Underline") { toggleUnderline() }
            }

            Divider()
                .frame(height: 20)
                .background(AppTheme.textMuted.opacity(0.3))

            // Headings
            Group {
                toolbarTextButton(label: "H1", tooltip: "Heading 1") { applyHeading(size: 24) }
                toolbarTextButton(label: "H2", tooltip: "Heading 2") { applyHeading(size: 20) }
                toolbarTextButton(label: "H3", tooltip: "Heading 3") { applyHeading(size: 16) }
            }

            Divider()
                .frame(height: 20)
                .background(AppTheme.textMuted.opacity(0.3))

            // Lists
            Group {
                toolbarButton(icon: "list.bullet", tooltip: "Bullet List") { insertBulletList() }
                toolbarButton(icon: "list.number", tooltip: "Numbered List") { insertNumberedList() }
            }

            Divider()
                .frame(height: 20)
                .background(AppTheme.textMuted.opacity(0.3))

            // Code
            Group {
                toolbarTextButton(label: "</>", tooltip: "Code Block") { applyCodeBlock() }
                toolbarTextButton(label: "`c`", tooltip: "Inline Code") { applyInlineCode() }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(AppTheme.surface)
    }

    // MARK: - Button builders

    @ViewBuilder
    private func toolbarButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundColor(AppTheme.textPrimary)
                .background(AppTheme.card.opacity(0.6))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    @ViewBuilder
    private func toolbarTextButton(label: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(minWidth: 28, minHeight: 28)
                .foregroundColor(AppTheme.textPrimary)
                .background(AppTheme.card.opacity(0.6))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    // MARK: - Formatting actions

    private func toggleBold() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textView.textStorage?.beginEditing()
        textView.textStorage?.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            let currentFont = (value as? NSFont) ?? NSFont.systemFont(ofSize: 14)
            let traits = currentFont.fontDescriptor.symbolicTraits
            let newFont: NSFont
            if traits.contains(.bold) {
                newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask)
            } else {
                newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
            }
            textView.textStorage?.addAttribute(.font, value: newFont, range: attrRange)
        }
        textView.textStorage?.endEditing()
        textView.didChangeText()
    }

    private func toggleItalic() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textView.textStorage?.beginEditing()
        textView.textStorage?.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            let currentFont = (value as? NSFont) ?? NSFont.systemFont(ofSize: 14)
            let traits = currentFont.fontDescriptor.symbolicTraits
            let newFont: NSFont
            if traits.contains(.italic) {
                newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask)
            } else {
                newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
            }
            textView.textStorage?.addAttribute(.font, value: newFont, range: attrRange)
        }
        textView.textStorage?.endEditing()
        textView.didChangeText()
    }

    private func toggleUnderline() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textView.textStorage?.beginEditing()
        textView.textStorage?.enumerateAttribute(.underlineStyle, in: range, options: []) { value, attrRange, _ in
            let currentStyle = (value as? Int) ?? 0
            if currentStyle != 0 {
                textView.textStorage?.removeAttribute(.underlineStyle, range: attrRange)
            } else {
                textView.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: attrRange)
            }
        }
        textView.textStorage?.endEditing()
        textView.didChangeText()
    }

    private func applyHeading(size: CGFloat) {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        let boldFont = NSFont.boldSystemFont(ofSize: size)
        textView.textStorage?.beginEditing()
        textView.textStorage?.addAttribute(.font, value: boldFont, range: range)
        textView.textStorage?.endEditing()
        textView.didChangeText()
    }

    private func insertBulletList() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()

        if range.length > 0 {
            // Prefix each line of selection
            let text = (textView.string as NSString).substring(with: range)
            let lines = text.components(separatedBy: "\n")
            let bulleted = lines.map { "• \($0)" }.joined(separator: "\n")
            let attrString = NSAttributedString(string: bulleted, attributes: textView.typingAttributes)
            textView.insertText(attrString, replacementRange: range)
        } else {
            let attrString = NSAttributedString(string: "• ", attributes: textView.typingAttributes)
            textView.insertText(attrString, replacementRange: range)
        }
    }

    private func insertNumberedList() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()

        if range.length > 0 {
            let text = (textView.string as NSString).substring(with: range)
            let lines = text.components(separatedBy: "\n")
            let numbered = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            let attrString = NSAttributedString(string: numbered, attributes: textView.typingAttributes)
            textView.insertText(attrString, replacementRange: range)
        } else {
            let attrString = NSAttributedString(string: "1. ", attributes: textView.typingAttributes)
            textView.insertText(attrString, replacementRange: range)
        }
    }

    private func applyCodeBlock() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let codeBackground = NSColor(red: 0x1E / 255.0, green: 0x1E / 255.0, blue: 0x2E / 255.0, alpha: 1.0)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 16
        paragraphStyle.firstLineHeadIndent = 16
        paragraphStyle.tailIndent = -16

        textView.textStorage?.beginEditing()
        textView.textStorage?.addAttributes([
            .font: monoFont,
            .backgroundColor: codeBackground,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xE8 / 255.0, alpha: 1.0)
        ], range: range)
        textView.textStorage?.endEditing()
        textView.didChangeText()
    }

    private func applyInlineCode() {
        guard let textView = editorState.textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let inlineBackground = NSColor(red: 0x2A / 255.0, green: 0x2A / 255.0, blue: 0x3E / 255.0, alpha: 1.0)

        textView.textStorage?.beginEditing()
        textView.textStorage?.addAttributes([
            .font: monoFont,
            .backgroundColor: inlineBackground
        ], range: range)
        textView.textStorage?.endEditing()
        textView.didChangeText()
    }
}
