import SwiftUI
import AppKit

// MARK: - Shared text view state for toolbar communication

class RichTextEditorState: ObservableObject {
    weak var textView: NSTextView?
}

// MARK: - NSViewRepresentable wrapping NSTextView

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var editorState: RichTextEditorState
    var onTextChange: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Configure text view
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFontPanel = false
        textView.usesRuler = false

        // Appearance
        textView.backgroundColor = NSColor(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x2E / 255.0, alpha: 1.0) // AppTheme.background #1A1A2E
        textView.insertionPointColor = .white
        textView.textColor = NSColor(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xE8 / 255.0, alpha: 1.0) // AppTheme.textPrimary
        textView.font = NSFont.systemFont(ofSize: 14)

        // Default typing attributes
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor(red: 0xE8 / 255.0, green: 0xE8 / 255.0, blue: 0xE8 / 255.0, alpha: 1.0)
        ]

        // Layout
        textView.textContainerInset = NSSize(width: 24, height: 16)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        // Scroll view appearance
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        // Set delegate
        textView.delegate = context.coordinator

        // Load initial content
        if attributedText.length > 0 {
            textView.textStorage?.setAttributedString(attributedText)
        }

        // Share reference with toolbar
        DispatchQueue.main.async {
            self.editorState.textView = textView
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Only update if the binding changed externally (not from typing)
        if !context.coordinator.isEditing {
            let currentText = textView.attributedString()
            if currentText != attributedText {
                textView.textStorage?.setAttributedString(attributedText)
            }
        }

        // Ensure state reference is up to date
        if editorState.textView !== textView {
            DispatchQueue.main.async {
                self.editorState.textView = textView
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isEditing = true
            parent.attributedText = textView.attributedString()
            parent.onTextChange?()
            isEditing = false
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }
    }
}
