import Combine
import Foundation

@MainActor
public final class EditorCommandCenter: ObservableObject {
    public struct Request: Equatable, Sendable {
        public let id: UUID
        public let action: MarkdownFormatting.Action
    }

    @Published public private(set) var request: Request?

    public init() {}

    public func send(_ action: MarkdownFormatting.Action) {
        request = Request(id: UUID(), action: action)
    }
}
