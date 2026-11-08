import SwiftUI
import KeyboardShortcuts

/// Every shortcut is user-recordable here — click the box, press a new
/// combo, done. KeyboardShortcuts persists it automatically.
struct SettingsView: View {
    @State private var loginItem = LoginItem()
    @State private var launchAtLoginEnabled = false
    @AppStorage(NotchController.keyboardOnlyKey) private var keyboardOnly = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    launchAtLoginRow
                    keyboardOnlyRow

                    Divider().background(.white.opacity(0.1))

                    Text("Keyboard Shortcuts")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ShortcutRow(label: "Toggle notch", name: .toggleNotch)
                    ShortcutRow(label: "Quick-add todo", name: .quickAddTodo)
                    ShortcutRow(label: "Quick-open scripts", name: .quickScripts)
                    Divider().background(.white.opacity(0.1))
                    ShortcutRow(label: "Go to Home", name: .goHome)
                    ShortcutRow(label: "Go to Todo", name: .goTodo)
                    ShortcutRow(label: "Go to Scripts", name: .goScripts)
                    ShortcutRow(label: "Go to Monitor", name: .goMonitor)
                    ShortcutRow(label: "Go to Cleanup", name: .goCleanup)
                    ShortcutRow(label: "Go to Settings", name: .goSettings)

                    Text("Esc closes the notch while it's open via keyboard. ⌘Q quits.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            footer
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
        .onAppear { launchAtLoginEnabled = loginItem.isEnabled }
    }

    /// Kept outside the scroll view so Quit is always one click away.
    private var footer: some View {
        HStack(spacing: 8) {
            Text("Island \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            PillButton(title: "Welcome tour", systemImage: "sparkles") {
                OnboardingWindowController.shared.show()
            }
            PillButton(title: "Quit Island", systemImage: "power") {
                NSApp.terminate(nil)
            }
            .help("Quit Island (⌘Q)")
        }
    }

    private var keyboardOnlyRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Keyboard only")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                Text("Hovering the notch won't open it — use the toggle shortcut")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $keyboardOnly)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private var launchAtLoginRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Launch at login")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                Text("Island starts automatically when you log in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $launchAtLoginEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .onChange(of: launchAtLoginEnabled) { _, newValue in
                    loginItem.setEnabled(newValue)
                }
        }
    }
}

private struct ShortcutRow: View {
    let label: String
    let name: KeyboardShortcuts.Name

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white)
            Spacer()
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}
