import AppKit

/// "Move to Applications" for people who double-click Island straight out of
/// Downloads. Running from there breaks launch-at-login (SMAppService
/// registers the current path) and Gatekeeper may run it from a read-only,
/// randomized copy (App Translocation), so settings appear not to stick.
enum AppInstaller {
    private static var bundleURL: URL { Bundle.main.bundleURL }
    private static let destination = URL(fileURLWithPath: "/Applications").appendingPathComponent("Island.app")

    /// False for `swift run` dev builds, which aren't an .app bundle.
    static var needsInstall: Bool {
        guard bundleURL.pathExtension == "app" else { return false }
        let path = bundleURL.resolvingSymlinksInPath().path
        let userApplications = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        return !path.hasPrefix("/Applications/") && !path.hasPrefix(userApplications + "/")
    }

    /// Moves (or copies, when translocated/read-only) the bundle into
    /// /Applications, relaunches from there, and quits this instance.
    static func moveToApplications() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: destination.path) {
            try fm.trashItem(at: destination, resultingItemURL: nil)
        }
        do {
            try fm.moveItem(at: bundleURL, to: destination)
        } catch {
            try fm.copyItem(at: bundleURL, to: destination)
        }

        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: destination, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}
