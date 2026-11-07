import KeyboardShortcuts

/// All user-customizable global shortcuts. Defaults are suggestions only —
/// KeyboardShortcuts persists whatever the user records to UserDefaults, so
/// every one of these is reassignable from Settings.
extension KeyboardShortcuts.Name {
    static let toggleNotch = Self("toggleNotch", default: .init(.space, modifiers: [.option]))
    static let quickAddTodo = Self("quickAddTodo", default: .init(.t, modifiers: [.option]))
    static let quickScripts = Self("quickScripts", default: .init(.s, modifiers: [.option]))

    static let goHome = Self("goHome", default: .init(.one, modifiers: [.option]))
    static let goTodo = Self("goTodo", default: .init(.two, modifiers: [.option]))
    static let goScripts = Self("goScripts", default: .init(.three, modifiers: [.option]))
    static let goMonitor = Self("goMonitor", default: .init(.four, modifiers: [.option]))
    static let goCleanup = Self("goCleanup", default: .init(.five, modifiers: [.option]))
    static let goSettings = Self("goSettings", default: .init(.six, modifiers: [.option]))
}
