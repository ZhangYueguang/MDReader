import AppKit
import SwiftUI

public struct MarkdownEditorView: NSViewRepresentable {
    @Binding private var text: String
    private let command: EditorCommandCenter.Request?

    public init(
        text: Binding<String>,
        command: EditorCommandCenter.Request?
    ) {
        self._text = text
        self.command = command
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        let textView = NSTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.string = text
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .controlAccentColor
        textView.textContainerInset = NSSize(width: 34, height: 28)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.defaultParagraphStyle = Self.paragraphStyle
        textView.typingAttributes = Self.baseAttributes
        textView.setAccessibilityLabel("Markdown source editor")

        scrollView.documentView = textView
        context.coordinator.attach(textView)
        context.coordinator.applyHighlighting()
        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            context.coordinator.replaceWithExternalText(text, in: textView)
        }
        if let command, command.id != context.coordinator.lastCommandID {
            context.coordinator.apply(command, to: textView)
        }
    }

    public static func dismantleNSView(
        _ scrollView: NSScrollView,
        coordinator: Coordinator
    ) {
        NSObject.cancelPreviousPerformRequests(
            withTarget: coordinator,
            selector: #selector(Coordinator.applyHighlighting),
            object: nil
        )
        (scrollView.documentView as? NSTextView)?.delegate = nil
        coordinator.detach()
    }

    private static let paragraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.paragraphSpacing = 1
        style.tabStops = stride(from: 28, through: 280, by: 28).map {
            NSTextTab(textAlignment: .left, location: CGFloat($0))
        }
        style.defaultTabInterval = 28
        return style
    }()

    private static var baseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: paragraphStyle,
        ]
    }

    @MainActor
    public final class Coordinator: NSObject, NSTextViewDelegate {
        fileprivate var parent: MarkdownEditorView
        fileprivate var lastCommandID: UUID?
        private weak var textView: NSTextView?
        private var isSynchronizing = false

        fileprivate init(parent: MarkdownEditorView) {
            self.parent = parent
        }

        fileprivate func attach(_ textView: NSTextView) {
            self.textView = textView
        }

        fileprivate func detach() {
            textView = nil
        }

        public func textDidChange(_ notification: Notification) {
            guard !isSynchronizing,
                  let textView = notification.object as? NSTextView else {
                return
            }
            parent.text = textView.string
            scheduleHighlighting()
        }

        fileprivate func replaceWithExternalText(
            _ text: String,
            in textView: NSTextView
        ) {
            let selection = textView.selectedRange()
            isSynchronizing = true
            textView.string = text
            textView.setSelectedRange(clamped(selection, to: (text as NSString).length))
            isSynchronizing = false
            applyHighlighting()
        }

        fileprivate func apply(
            _ request: EditorCommandCenter.Request,
            to textView: NSTextView
        ) {
            lastCommandID = request.id
            let result = MarkdownFormatting.apply(
                request.action,
                to: textView.string,
                selectedRange: textView.selectedRange()
            )
            let fullRange = NSRange(
                location: 0,
                length: (textView.string as NSString).length
            )
            guard textView.shouldChangeText(
                in: fullRange,
                replacementString: result.text
            ) else {
                return
            }
            textView.textStorage?.replaceCharacters(
                in: fullRange,
                with: result.text
            )
            textView.didChangeText()
            textView.setSelectedRange(result.selectedRange)
            textView.scrollRangeToVisible(result.selectedRange)
            textView.window?.makeFirstResponder(textView)
        }

        private func scheduleHighlighting() {
            NSObject.cancelPreviousPerformRequests(
                withTarget: self,
                selector: #selector(applyHighlighting),
                object: nil
            )
            perform(#selector(applyHighlighting), with: nil, afterDelay: 0.08)
        }

        @objc fileprivate func applyHighlighting() {
            guard let textView,
                  let layoutManager = textView.layoutManager else {
                return
            }
            let source = textView.string
            let fullRange = NSRange(
                location: 0,
                length: (source as NSString).length
            )
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: fullRange)
            layoutManager.removeTemporaryAttribute(.font, forCharacterRange: fullRange)

            for token in MarkdownSyntaxHighlighter.tokens(in: source) {
                layoutManager.addTemporaryAttributes(
                    attributes(for: token.kind),
                    forCharacterRange: token.range
                )
            }
        }

        private func attributes(
            for kind: MarkdownSyntaxHighlighter.TokenKind
        ) -> [NSAttributedString.Key: Any] {
            switch kind {
            case .heading:
                return [
                    .foregroundColor: NSColor.systemTeal,
                    .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .semibold),
                ]
            case .link:
                return [.foregroundColor: NSColor.linkColor]
            case .code, .codeBlock:
                return [.foregroundColor: NSColor.systemOrange]
            case .math:
                return [.foregroundColor: NSColor.systemPurple]
            case .comment:
                return [.foregroundColor: NSColor.secondaryLabelColor]
            case .quote, .listMarker:
                return [.foregroundColor: NSColor.systemTeal.withAlphaComponent(0.78)]
            case .strong:
                return [
                    .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
                ]
            case .emphasis:
                return [
                    .font: NSFontManager.shared.convert(
                        NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                        toHaveTrait: .italicFontMask
                    )
                ]
            case .strikethrough:
                return [.foregroundColor: NSColor.tertiaryLabelColor]
            }
        }

        private func clamped(_ range: NSRange, to length: Int) -> NSRange {
            let location = min(range.location, length)
            return NSRange(
                location: location,
                length: min(range.length, length - location)
            )
        }
    }
}
