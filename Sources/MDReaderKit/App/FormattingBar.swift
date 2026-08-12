import SwiftUI

public struct FormattingBar: View {
    private let perform: (MarkdownFormatting.Action) -> Void

    public init(perform: @escaping (MarkdownFormatting.Action) -> Void) {
        self.perform = perform
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                Menu {
                    ForEach(1...6, id: \.self) { level in
                        Button("Heading \(level)") {
                            perform(.heading(level: level))
                        }
                    }
                } label: {
                    formatLabel("H", help: "Heading")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                formatButton("bold", "Bold", .bold, shortcut: "B")
                formatButton("italic", "Italic", .italic, shortcut: "I")
                formatButton("strikethrough", "Strikethrough", .strikethrough)

                divider

                formatButton("link", "Link", .link)
                formatButton("quote.opening", "Block Quote", .blockQuote)
                formatButton("chevron.left.forwardslash.chevron.right", "Inline Code", .inlineCode)
                formatButton("curlybraces", "Code Block", .codeBlock)
                formatButton("function", "Inline Math", .inlineMath)
                formatButton("sum", "Display Math", .displayMath)

                divider

                formatButton("list.bullet", "Bulleted List", .bulletedList)
                formatButton("list.number", "Numbered List", .numberedList)
                formatButton("checklist", "Task List", .taskList)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Markdown formatting")
    }

    private var divider: some View {
        Divider()
            .frame(height: 20)
            .padding(.horizontal, 5)
    }

    private func formatButton(
        _ symbol: String,
        _ help: String,
        _ action: MarkdownFormatting.Action,
        shortcut: Character? = nil
    ) -> some View {
        Button {
            perform(action)
        } label: {
            formatLabel(symbol, help: help)
        }
        .buttonStyle(.plain)
        .help(shortcut.map { "\(help) (⌘\($0))" } ?? help)
        .accessibilityLabel(help)
    }

    private func formatLabel(_ symbol: String, help: String) -> some View {
        Group {
            if symbol.count == 1 {
                Text(symbol)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .foregroundStyle(.primary)
        .frame(width: 30, height: 28)
        .contentShape(Rectangle())
        .background(.primary.opacity(0.001), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(help)
    }
}
