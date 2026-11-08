import SwiftUI
import Combine
import DynamicNotchKit
import KeyboardShortcuts

/// Owns the single notch overlay instance and its expand/collapse lifecycle.
/// DynamicNotch itself only tracks `isHovering`; we watch that to flip between
/// `.compact()` (the idle pill) and `.expand()` (the dropdown) on hover.
/// Keyboard shortcuts drive the same expand/collapse, but need their own
/// "pinned open" flag so a hover-exit grace timer doesn't fight them.
@MainActor
final class NotchController {
    static let keyboardOnlyKey = "keyboardOnlyMode"
    private static weak var shared: NotchController?
    private var isPresentingModal = false

    private var notch: DynamicNotch<NotchExpandedView, NotchCompactLeading, EmptyView>?
    private var cancellable: AnyCancellable?
    private var escMonitor: Any?
    private var outsideClickMonitor: Any?
    private let todoStore = TodoStore()
    private let scriptStore = ScriptStore()
    private let systemStats = SystemStats()
    private let cleanupScanner = CleanupScanner()
    private let uiState = NotchUIState()

    func show() {
        let todoStore = todoStore
        let scriptStore = scriptStore
        let systemStats = systemStats
        let cleanupScanner = cleanupScanner
        let uiState = uiState
        let notch = DynamicNotch(
            hoverBehavior: [.keepVisible],
            style: .auto,
            expanded: { NotchExpandedView(todoStore: todoStore, scriptStore: scriptStore, systemStats: systemStats, cleanupScanner: cleanupScanner, uiState: uiState) },
            compactLeading: { NotchCompactLeading(store: todoStore, scriptStore: scriptStore) }
        )
        self.notch = notch
        Self.shared = self

        cancellable = notch.objectWillChange.sink { [weak self] _ in
            // objectWillChange fires before isHovering updates; dispatch to read the new value.
            DispatchQueue.main.async { self?.handleHoverChange() }
        }

        Task { await notch.compact() }
        registerShortcuts()
        registerEscToClose()
        registerOutsideClickToClose()
    }

    private var wasHovering = false
    private var collapseTask: Task<Void, Never>?
    private var expandTask: Task<Void, Never>?
    /// True while the notch was opened by a keyboard shortcut rather than
    /// hover — keeps it open even though the mouse never entered it.
    private var keyboardPinned = false

    /// Clicking a button inside the expanded view can momentarily register as
    /// mouse-exited (NSPanel losing hover tracking during the click), which
    /// used to collapse the notch mid-interaction. A short grace period before
    /// collapsing — cancelled if hover returns — fixes that jitter.
    private func handleHoverChange() {
        guard let notch else { return }
        guard notch.isHovering != wasHovering else { return }
        wasHovering = notch.isHovering

        if notch.isHovering {
            guard !UserDefaults.standard.bool(forKey: Self.keyboardOnlyKey) else { return }
            // Mouse has taken over — hand control back to normal hover
            // behavior so moving away afterward collapses it like usual.
            keyboardPinned = false
            collapseTask?.cancel()
            // Require the cursor to dwell briefly so merely passing over the notch doesn't open it.
            expandTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await notch.expand()
                // Lets typing (quick-add todo, recording a shortcut in
                // Settings) work even when opened by hover, not just keyboard.
                notch.windowController?.window?.makeKey()
            }
        } else {
            expandTask?.cancel()
            guard !keyboardPinned, !isPresentingModal else { return }
            collapseTask?.cancel()
            collapseTask = Task {
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }
                await notch.compact()
            }
        }
    }

    // MARK: - Keyboard

    private func registerShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .toggleNotch) { [weak self] in
            self?.toggleViaKeyboard()
        }
        KeyboardShortcuts.onKeyUp(for: .quickAddTodo) { [weak self] in
            self?.openViaKeyboard(on: .todo)
        }
        KeyboardShortcuts.onKeyUp(for: .quickScripts) { [weak self] in
            self?.openViaKeyboard(on: .scripts)
        }
        KeyboardShortcuts.onKeyUp(for: .goHome) { [weak self] in self?.openViaKeyboard(on: .home) }
        KeyboardShortcuts.onKeyUp(for: .goTodo) { [weak self] in self?.openViaKeyboard(on: .todo) }
        KeyboardShortcuts.onKeyUp(for: .goScripts) { [weak self] in self?.openViaKeyboard(on: .scripts) }
        KeyboardShortcuts.onKeyUp(for: .goMonitor) { [weak self] in self?.openViaKeyboard(on: .monitor) }
        KeyboardShortcuts.onKeyUp(for: .goCleanup) { [weak self] in self?.openViaKeyboard(on: .cleanup) }
        KeyboardShortcuts.onKeyUp(for: .goSettings) { [weak self] in self?.openViaKeyboard(on: .settings) }
    }

    private func toggleViaKeyboard() {
        if keyboardPinned {
            closeViaKeyboard()
        } else {
            openViaKeyboard(on: uiState.tab)
        }
    }

    private func openViaKeyboard(on tab: NotchTab) {
        guard let notch else { return }
        collapseTask?.cancel()
        expandTask?.cancel()
        keyboardPinned = true
        uiState.tab = tab

        Task {
            await notch.expand()
            // .nonactivatingPanel can still become key without stealing focus
            // from the frontmost app — needed so typing (e.g. quick-add todo)
            // actually reaches the SwiftUI text field.
            notch.windowController?.window?.makeKey()
        }
    }

    private func closeViaKeyboard() {
        guard let notch else { return }
        keyboardPinned = false
        Task { await notch.compact() }
    }

    /// Opens the notch from outside the notch itself (e.g. the onboarding window's last step).
    func open(on tab: NotchTab) {
        openViaKeyboard(on: tab)
    }

    /// The notch panel sits at .screenSaver level, so a plain runModal() draws
    /// the open panel *underneath* it, and moving the mouse onto the dialog
    /// collapses the notch and throws away the form that asked for it. Raise
    /// the dialog above the notch and hold the notch open until it's dismissed.
    static func runModal(_ panel: NSOpenPanel) -> URL? {
        let controller = shared
        let notchWindow = controller?.notch?.windowController?.window
        controller?.isPresentingModal = true
        NSApp.activate(ignoringOtherApps: true)
        panel.level = NSWindow.Level(rawValue: (notchWindow?.level ?? .screenSaver).rawValue + 1)
        let url = panel.runModal() == .OK ? panel.url : nil
        controller?.isPresentingModal = false
        notchWindow?.makeKey()
        if let controller, let notch = controller.notch, !notch.isHovering, !controller.keyboardPinned {
            Task { await notch.compact() }
        }
        return url
    }

    private func registerEscToClose() {
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window == self.notch?.windowController?.window else { return event }
            // An accessory app has no menu bar, so ⌘Q needs wiring by hand.
            if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }
            guard event.keyCode == 53 /* Esc */ else { return event }
            self.closeViaKeyboard()
            return nil
        }
    }

    /// Clicking anywhere outside the panel closes a keyboard-opened notch —
    /// matches how Spotlight/Raycast-style overlays behave. A global monitor
    /// only reports clicks in OTHER apps/windows, so clicks inside our own
    /// panel (buttons, text fields) are never affected by this.
    private func registerOutsideClickToClose() {
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.keyboardPinned, !self.isPresentingModal else { return }
            self.closeViaKeyboard()
        }
    }
}
