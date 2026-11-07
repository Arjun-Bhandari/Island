import SwiftUI
import KeyboardShortcuts

/// Every shortcut is user-recordable here — click the box, press a new
/// combo, done. KeyboardShortcuts persists it automatically.
struct SettingsView: View {
    @State private var loginItem = LoginItem()
    @State private var launchAtLoginEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            launchAtLoginRow

            Divider().background(.white.opacity(0.1))

            Text("Keyboard Shortcuts")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView {
                VStack(spacing: 8) {
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
                }
            }
            .frame(maxHeight: 170)

            Text("Esc always closes the notch while it's open via keyboard.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
        .onAppear { launchAtLoginEnabled = loginItem.isEnabled }
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
