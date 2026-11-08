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
    /// SF Symbol picked by the user. Optional so scripts.json files saved
    /// before icons existed still decode; nil means "guess from the command".
    var icon: String?

    init(id: UUID = UUID(), name: String, command: String, workingDirectory: String = NSHomeDirectory(), icon: String? = nil) {
        self.id = id
        self.name = name
        self.command = command
        self.workingDirectory = workingDirectory
        self.icon = icon
    }

    var displayIcon: String { icon ?? ScriptIcon.suggested(for: command) }
}

enum ScriptIcon {
    static let choices = [
        "terminal", "play", "hammer", "shippingbox", "server.rack", "globe",
        "arrow.triangle.branch", "square.stack.3d.up", "testtube.2", "ladybug", "bolt",
        "arrow.clockwise", "icloud.and.arrow.up", "externaldrive", "trash", "doc.text",
    ]

    static func suggested(for command: String) -> String {
        let tokens = Set(command.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        let rules: [(Set<String>, String)] = [
            (["test", "jest", "vitest", "pytest"], "testtube.2"),
            (["dev", "serve", "server", "start"], "server.rack"),
            (["build", "make", "compile"], "hammer"),
            (["deploy", "vercel", "fly", "netlify"], "icloud.and.arrow.up"),
            (["docker", "kubectl", "compose"], "square.stack.3d.up"),
            (["git", "gh"], "arrow.triangle.branch"),
            (["npm", "pnpm", "yarn", "bun", "brew", "pip", "install"], "shippingbox"),
            (["clean", "rm"], "trash"),
            (["open", "curl"], "globe"),
        ]
        return rules.first { !$0.0.isDisjoint(with: tokens) }?.1 ?? "terminal"
    }
}

enum ScriptRunStatus: Equatable {
    case idle
    case running
    case succeeded
    case failed(String)
}
