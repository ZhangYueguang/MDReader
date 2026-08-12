import Foundation

public enum MarkdownSyntaxHighlighter {
    public enum TokenKind: String, CaseIterable, Equatable, Hashable, Sendable {
        case heading
        case quote
        case listMarker
        case strong
        case emphasis
        case strikethrough
        case link
        case code
        case codeBlock
        case math
        case comment
    }

    public struct Token: Equatable, Sendable {
        public let kind: TokenKind
        public let range: NSRange
    }

    private struct Rule {
        let kind: TokenKind
        let expression: NSRegularExpression

        init(
            _ kind: TokenKind,
            _ pattern: String,
            options: NSRegularExpression.Options = []
        ) {
            self.kind = kind
            self.expression = try! NSRegularExpression(
                pattern: pattern,
                options: options
            )
        }
    }

    private static let blockRules: [Rule] = [
        Rule(.codeBlock, #"^```[^\n]*\n[\s\S]*?^```[ \t]*$"#, options: .anchorsMatchLines),
        Rule(.comment, #"<!--[\s\S]*?-->"#),
    ]

    private static let inlineRules: [Rule] = [
        Rule(.heading, #"^#{1,6}[ \t]+[^\n]+"#, options: .anchorsMatchLines),
        Rule(.quote, #"^[ \t]*>[ \t]+"#, options: .anchorsMatchLines),
        Rule(.listMarker, #"^[ \t]*(?:[-+*](?:[ \t]+\[[ xX]\])?|\d+[.)])[ \t]+"#, options: .anchorsMatchLines),
        Rule(.link, #"!?\[[^\]\n]+\]\([^\)\n]+\)"#),
        Rule(.code, #"`[^`\n]+`"#),
        Rule(.strikethrough, #"~~[^~\n]+~~"#),
        Rule(.strong, #"(?:\*\*[^*\n]+\*\*|__[^_\n]+__)"#),
        Rule(.emphasis, #"(?<!\*)\*[^*\n]+\*(?!\*)|(?<!_)_[^_\n]+_(?!_)"#),
        Rule(.math, #"\$\$[\s\S]+?\$\$|(?<!\$)\$[^$\n]+\$(?!\$)"#),
    ]

    public static func tokens(in source: String) -> [Token] {
        let fullRange = NSRange(location: 0, length: (source as NSString).length)
        let blockTokens = matches(rules: blockRules, source: source, range: fullRange)
        let inlineTokens = matches(rules: inlineRules, source: source, range: fullRange)
            .filter { candidate in
                !blockTokens.contains { block in
                    NSIntersectionRange(block.range, candidate.range).length > 0
                }
            }
        return (blockTokens + inlineTokens).sorted {
            if $0.range.location == $1.range.location {
                return $0.range.length > $1.range.length
            }
            return $0.range.location < $1.range.location
        }
    }

    private static func matches(
        rules: [Rule],
        source: String,
        range: NSRange
    ) -> [Token] {
        rules.flatMap { rule in
            rule.expression.matches(in: source, range: range).map {
                Token(kind: rule.kind, range: $0.range)
            }
        }
    }
}
