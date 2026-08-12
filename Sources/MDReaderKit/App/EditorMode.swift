public enum EditorMode: String, CaseIterable, Equatable, Sendable {
    case read = "Read"
    case edit = "Edit"

    public static let defaultMode: EditorMode = .read

    public var showsFormattingBar: Bool {
        self == .edit
    }

    public var showsSourceEditor: Bool {
        self == .edit
    }

    public func isAvailable(isEditable: Bool) -> Bool {
        self == .read || isEditable
    }
}
