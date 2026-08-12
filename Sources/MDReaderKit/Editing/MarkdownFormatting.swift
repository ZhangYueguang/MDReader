import Foundation

public enum MarkdownFormatting {
    public enum Action: Equatable, Sendable {
        case heading(level: Int)
        case bold
        case italic
        case strikethrough
        case link
        case blockQuote
        case inlineCode
        case codeBlock
        case inlineMath
        case displayMath
        case bulletedList
        case numberedList
        case taskList
    }

    public struct Result: Equatable, Sendable {
        public let text: String
        public let selectedRange: NSRange
    }

    public static func apply(
        _ action: Action,
        to text: String,
        selectedRange: NSRange
    ) -> Result {
        let source = text as NSString
        let safeRange = clamped(selectedRange, to: source.length)

        switch action {
        case .bold:
            return wrap("**", "**", text: text, range: safeRange)
        case .italic:
            return wrap("*", "*", text: text, range: safeRange)
        case .strikethrough:
            return wrap("~~", "~~", text: text, range: safeRange)
        case .inlineCode:
            return wrap("`", "`", text: text, range: safeRange)
        case .inlineMath:
            return wrap("$", "$", text: text, range: safeRange)
        case .link:
            return link(text: text, range: safeRange)
        case .displayMath:
            return blockWrap("$$\n", "\n$$", text: text, range: safeRange)
        case .codeBlock:
            return blockWrap("```\n", "\n```", text: text, range: safeRange)
        case let .heading(level):
            let safeLevel = min(max(level, 1), 6)
            return prefixLines(
                text: text,
                range: safeRange,
                prefix: String(repeating: "#", count: safeLevel) + " ",
                matchesTarget: { line in
                    line.hasPrefix(String(repeating: "#", count: safeLevel) + " ")
                }
            )
        case .blockQuote:
            return prefixLines(
                text: text,
                range: safeRange,
                prefix: "> ",
                matchesTarget: { $0.hasPrefix("> ") }
            )
        case .bulletedList:
            return listLines(text: text, range: safeRange, style: .bulleted)
        case .numberedList:
            return listLines(text: text, range: safeRange, style: .numbered)
        case .taskList:
            return listLines(text: text, range: safeRange, style: .task)
        }
    }

    private static func wrap(
        _ opening: String,
        _ closing: String,
        text: String,
        range: NSRange
    ) -> Result {
        let source = text as NSString
        let openingLength = (opening as NSString).length
        let closingLength = (closing as NSString).length
        let selected = source.substring(with: range)

        if range.location >= openingLength,
           NSMaxRange(range) + closingLength <= source.length,
           source.substring(
               with: NSRange(
                   location: range.location - openingLength,
                   length: openingLength
               )
           ) == opening,
           source.substring(
               with: NSRange(
                   location: NSMaxRange(range),
                   length: closingLength
               )
           ) == closing {
            let wrappedRange = NSRange(
                location: range.location - openingLength,
                length: openingLength + range.length + closingLength
            )
            let output = source.replacingCharacters(in: wrappedRange, with: selected)
            return Result(
                text: output,
                selectedRange: NSRange(
                    location: wrappedRange.location,
                    length: range.length
                )
            )
        }

        if range.length >= openingLength + closingLength,
           selected.hasPrefix(opening), selected.hasSuffix(closing) {
            let innerLength = range.length - openingLength - closingLength
            let innerRange = NSRange(
                location: range.location + openingLength,
                length: innerLength
            )
            let inner = source.substring(with: innerRange)
            let output = source.replacingCharacters(in: range, with: inner)
            return Result(
                text: output,
                selectedRange: NSRange(location: range.location, length: innerLength)
            )
        }

        let replacement = opening + selected + closing
        let output = source.replacingCharacters(in: range, with: replacement)
        return Result(
            text: output,
            selectedRange: NSRange(
                location: range.location + openingLength,
                length: range.length
            )
        )
    }

    private static func link(text: String, range: NSRange) -> Result {
        let source = text as NSString
        let selected = source.substring(with: range)
        let label = selected.isEmpty ? "text" : selected
        let replacement = "[\(label)](url)"
        let output = source.replacingCharacters(in: range, with: replacement)
        let labelLength = (label as NSString).length
        return Result(
            text: output,
            selectedRange: NSRange(
                location: range.location + labelLength + 3,
                length: 3
            )
        )
    }

    private static func blockWrap(
        _ opening: String,
        _ closing: String,
        text: String,
        range: NSRange
    ) -> Result {
        let source = text as NSString
        let selected = source.substring(with: range)
        let openingLength = (opening as NSString).length
        let closingLength = (closing as NSString).length
        let fenceOpening: String
        if opening == "```\n", selected.hasPrefix("```") {
            fenceOpening = selected.components(separatedBy: "\n").first.map {
                $0 + "\n"
            } ?? opening
        } else {
            fenceOpening = opening
        }
        if selected.hasPrefix(fenceOpening), selected.hasSuffix(closing),
           range.length >= (fenceOpening as NSString).length + closingLength {
            let innerRange = NSRange(
                location: range.location + (fenceOpening as NSString).length,
                length: range.length - (fenceOpening as NSString).length - closingLength
            )
            let inner = source.substring(with: innerRange)
            return Result(
                text: source.replacingCharacters(in: range, with: inner),
                selectedRange: NSRange(location: range.location, length: innerRange.length)
            )
        }
        let replacement = opening + selected + closing
        return Result(
            text: source.replacingCharacters(in: range, with: replacement),
            selectedRange: NSRange(
                location: range.location + openingLength,
                length: range.length
            )
        )
    }

    private static func prefixLines(
        text: String,
        range: NSRange,
        prefix: String,
        matchesTarget: (String) -> Bool
    ) -> Result {
        transformLines(text: text, range: range) { lines in
            let shouldRemove = lines.allSatisfy(matchesTarget)
            return lines.enumerated().map { _, line in
                let content = removingBlockPrefix(from: line)
                return shouldRemove ? content : prefix + content
            }
        }
    }

    private enum ListStyle {
        case bulleted
        case numbered
        case task
    }

    private static func listLines(
        text: String,
        range: NSRange,
        style: ListStyle
    ) -> Result {
        transformLines(text: text, range: range) { lines in
            let shouldRemove = lines.allSatisfy { line in
                switch style {
                case .bulleted:
                    return line.range(of: #"^\s*[-+*]\s+(?!\[[ xX]\])"#, options: .regularExpression) != nil
                case .numbered:
                    return line.range(of: #"^\s*\d+[.)]\s+"#, options: .regularExpression) != nil
                case .task:
                    return line.range(of: #"^\s*[-+*]\s+\[[ xX]\]\s+"#, options: .regularExpression) != nil
                }
            }
            let cleaned = lines.map(removingListPrefix)
            if shouldRemove {
                return cleaned
            }
            return cleaned.enumerated().map { index, line in
                switch style {
                case .bulleted:
                    return "- " + line
                case .numbered:
                    return "\(index + 1). " + line
                case .task:
                    return "- [ ] " + line
                }
            }
        }
    }

    private static func transformLines(
        text: String,
        range: NSRange,
        transform: ([String]) -> [String]
    ) -> Result {
        let source = text as NSString
        let lineRange = source.lineRange(for: range)
        let selectedLines = source.substring(with: lineRange)
        let hasTrailingNewline = selectedLines.hasSuffix("\n")
        var body = selectedLines
        if hasTrailingNewline {
            body.removeLast()
        }
        let lines = body.components(separatedBy: "\n")
        var replacement = transform(lines).joined(separator: "\n")
        if hasTrailingNewline {
            replacement.append("\n")
        }
        let output = source.replacingCharacters(in: lineRange, with: replacement)
        return Result(
            text: output,
            selectedRange: NSRange(
                location: lineRange.location,
                length: (replacement as NSString).length
            )
        )
    }

    private static func removingBlockPrefix(from line: String) -> String {
        line.replacingOccurrences(
            of: #"^(?:#{1,6}|>)\s+"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func removingListPrefix(from line: String) -> String {
        line.replacingOccurrences(
            of: #"^\s*(?:(?:[-+*])\s+(?:\[[ xX]\]\s+)?|\d+[.)]\s+)"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func clamped(_ range: NSRange, to length: Int) -> NSRange {
        let location = min(max(range.location, 0), length)
        let remaining = length - location
        return NSRange(
            location: location,
            length: min(max(range.length, 0), remaining)
        )
    }
}
