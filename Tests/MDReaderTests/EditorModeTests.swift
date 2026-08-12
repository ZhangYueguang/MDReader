import MDReaderKit

func editorModeTests() -> [TestCase] {
    [
        TestCase("Document workspace starts in Read mode") {
            try expectEqual(EditorMode.defaultMode, .read)
            try expectEqual(EditorMode.read.showsFormattingBar, false)
            try expectEqual(EditorMode.read.showsSourceEditor, false)
        },
        TestCase("Edit mode shows source controls") {
            try expectEqual(EditorMode.edit.showsFormattingBar, true)
            try expectEqual(EditorMode.edit.showsSourceEditor, true)
        },
        TestCase("Edit mode is unavailable for a read-only file") {
            try expectEqual(EditorMode.read.isAvailable(isEditable: false), true)
            try expectEqual(EditorMode.edit.isAvailable(isEditable: false), false)
            try expectEqual(EditorMode.edit.isAvailable(isEditable: true), true)
        },
    ]
}
