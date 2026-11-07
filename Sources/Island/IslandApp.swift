import SwiftUI
import AppKit
import DynamicNotchKit

@main
struct IslandApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // no dock icon, menu-bar-style agent
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = NotchController()
        controller?.show()
    }
}
