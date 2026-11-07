import Foundation

/// A user-defined shell command. Command text is only ever typed/pasted by
/// the user in this app — never fetched remotely — so running it is safe to
/// hand to friends.
struct ScriptItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    /// Working directory the command runs from. Defaults to the home
    /// directory, same as opening a fresh Terminal tab.
    var workingDirectory: String

    init(id: UUID = UUID(), name: String, command: String, workingDirectory: String = NSHomeDirectory()) {
        self.id = id
        self.name = name
        self.command = command
        self.workingDirectory = workingDirectory
    }
}

enum ScriptRunStatus: Equatable {
    case idle
    case running
    case succeeded
    case failed(String)
}
