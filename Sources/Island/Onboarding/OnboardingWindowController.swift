import AppKit
import SwiftUI

/// First-launch welcome tour, also reachable from Settings → Welcome tour.
/// A regular window rather than notch content: the notch is tiny, hover-driven
/// and collapses on its own, which is the wrong place to teach someone how it works.
@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowController()
    static let completedKey = "hasCompletedOnboarding"

    /// Set by AppDelegate so the last step can hand off to the real notch.
    var openNotch: ((NotchTab) -> Void)?
    private var window: NSWindow?

    static var shouldShowOnLaunch: Bool {
        !UserDefaults.standard.bool(forKey: completedKey)
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.backgroundColor = .black
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.delegate = self
            window.contentView = NSHostingView(rootView: OnboardingView(finish: { [weak self] in self?.finish() }))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        window?.close()
        openNotch?(.home)
    }

    func windowWillClose(_ notification: Notification) {
        // Closing early counts as done too — the tour is always in Settings.
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        window = nil
    }
}
