import SwiftUI
import AppKit
import KeyboardShortcuts

struct ScriptRunnerView: View {
    @Bindable var store: ScriptStore
    @State private var showingForm = false
    @State private var editingItem: ScriptItem?
    /// Fixed up front so the form's shortcut recorder has a name before saving.
    @State private var draftID = UUID()
    @State private var draftName = ""
    @State private var draftCommand = ""
    @State private var draftDirectory = NSHomeDirectory()
    /// nil = automatic icon, guessed from the command as the user types.
    @State private var draftIcon: String?
    @FocusState private var nameFocused: Bool

    private var canSave: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty
            && !draftCommand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if showingForm {
                form
            } else if store.scripts.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showingForm)
    }

    private var header: some View {
        HStack {
            Text(showingForm ? (editingItem == nil ? "New script" : "Edit script") : "Scripts")
                .font(.headline)
                .foregroundStyle(.white)
            if !showingForm, !store.scripts.isEmpty {
                Text("\(store.scripts.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.white.opacity(0.08), in: Capsule())
            }
            Spacer()
            if !showingForm, !store.scripts.isEmpty {
                PillButton(title: "New script", systemImage: "plus", action: beginAdd)
            }
        }
        .frame(height: 24)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            Text("No scripts yet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Text("Save commands you run often, then run them from here or with a shortcut.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                PillButton(title: "New script", systemImage: "plus", primary: true, action: beginAdd)
                PillButton(title: "Import .sh file", systemImage: "doc.badge.plus", action: importScriptFile)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(store.scripts) { item in
                    ScriptRow(item: item, store: store, onEdit: { beginEdit(item) })
                }
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: draftIcon ?? ScriptIcon.suggested(for: draftCommand))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                    .contentTransition(.symbolEffect(.replace))
                FormField(placeholder: "Name, e.g. Start API", text: $draftName)
                    .focused($nameFocused)
                KeyboardShortcuts.Recorder(for: ScriptStore.runShortcutName(for: draftID))
                    .controlSize(.large)
                    .frame(width: 140)
                    .help("Optional global shortcut that runs or stops this script")
            }

            FormField(placeholder: "Command, e.g. npm run dev", text: $draftCommand, monospaced: true)
                .onSubmit { if canSave { saveForm() } }

            iconPicker

            HStack(spacing: 8) {
                Button(action: pickWorkingDirectory) {
                    HStack(spacing: 5) {
                        Image(systemName: "folder")
                        Text(displayPath(draftDirectory))
                            .lineLimit(1)
                            .truncationMode(.head)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(.white.opacity(0.08), in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Folder the command runs in")
                .frame(maxWidth: 200, alignment: .leading)

                if editingItem == nil {
                    Button("Import .sh…", action: importScriptFile)
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                PillButton(title: "Cancel", action: cancelForm)
                    .keyboardShortcut(.cancelAction)
                PillButton(title: editingItem == nil ? "Add script" : "Save", primary: true, action: saveForm)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.4)
            }
        }
    }

    private var iconPicker: some View {
        HStack(spacing: 4) {
            IconChip(symbol: "sparkles", isSelected: draftIcon == nil, help: "Automatic — picked from the command") {
                draftIcon = nil
            }
            Divider().frame(height: 18).background(.white.opacity(0.15))
            ForEach(ScriptIcon.choices, id: \.self) { symbol in
                IconChip(symbol: symbol, isSelected: draftIcon == symbol, help: nil) {
                    draftIcon = symbol
                }
            }
        }
    }

    private func beginAdd() {
        resetDraft()
        showingForm = true
        nameFocused = true
    }

    private func beginEdit(_ item: ScriptItem) {
        editingItem = item
        draftID = item.id
        draftName = item.name
        draftCommand = item.command
        draftDirectory = item.workingDirectory
        draftIcon = item.icon
        showingForm = true
    }

    private func saveForm() {
        guard canSave else { return }
        if let editingItem {
            store.update(editingItem, name: draftName, command: draftCommand, workingDirectory: draftDirectory, icon: draftIcon)
        } else {
            store.add(id: draftID, name: draftName, command: draftCommand, workingDirectory: draftDirectory, icon: draftIcon)
        }
        cancelForm()
    }

    private func cancelForm() {
        if editingItem == nil, !store.scripts.contains(where: { $0.id == draftID }) {
            KeyboardShortcuts.reset(ScriptStore.runShortcutName(for: draftID)) // don't leave an orphaned binding
        }
        resetDraft()
        showingForm = false
    }

    private func resetDraft() {
        editingItem = nil
        draftID = UUID()
        draftName = ""
        draftCommand = ""
        draftDirectory = NSHomeDirectory()
        draftIcon = nil
    }

    private func pickWorkingDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"
        panel.message = "Choose the folder this script runs in"
        panel.directoryURL = URL(fileURLWithPath: draftDirectory)
        if let url = NotchController.runModal(panel) {
            draftDirectory = url.path
        }
    }

    /// Lets the user pick an existing .sh/.command file and turns it into a
    /// runnable script entry — no need to retype the command by hand.
    private func importScriptFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Import"
        panel.message = "Choose a shell script to add"
        guard let url = NotchController.runModal(panel) else { return }
        if !showingForm { resetDraft() }
        if draftName.isEmpty {
            draftName = url.deletingPathExtension().lastPathComponent
        }
        draftCommand = "bash \(shellQuote(url.path))"
        draftDirectory = url.deletingLastPathComponent().path
        showingForm = true
    }

    private func shellQuote(_ path: String) -> String {
        "'\(path.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func displayPath(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}

// MARK: - Row

private struct ScriptRow: View {
    let item: ScriptItem
    let store: ScriptStore
    let onEdit: () -> Void
    @State private var hovering = false
    @State private var confirmingDelete = false

    private var status: ScriptRunStatus { store.status(for: item) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.displayIcon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    statusBadge
                }
                subtitle
            }

            Spacer(minLength: 4)

            if let shortcut = KeyboardShortcuts.getShortcut(for: ScriptStore.runShortcutName(for: item.id)) {
                Text(shortcut.description)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.15)))
                    .help("Runs or stops this script from anywhere")
            }

            if confirmingDelete {
                Button("Delete") { store.delete(item) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(.red.opacity(0.8), in: Capsule())
            } else {
                RowIconButton(symbol: "pencil", help: "Edit", action: onEdit)
                RowIconButton(symbol: "trash", help: "Delete") { confirmDelete() }
            }

            Button { store.toggle(item) } label: {
                Image(systemName: store.isRunning(item) ? "stop.fill" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(store.isRunning(item) ? .white : .black)
                    .frame(width: 28, height: 28)
                    .background(store.isRunning(item) ? Color.orange : Color.white, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(store.isRunning(item) ? "Stop" : "Run")
            .accessibilityLabel(store.isRunning(item) ? "Stop \(item.name)" : "Run \(item.name)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.white.opacity(hovering ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 10))
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    private var tint: Color {
        switch status {
        case .idle: .white
        case .running: .orange
        case .succeeded: .green
        case .failed: .red
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .idle: EmptyView()
        case .running:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("Running")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.orange)
        case .succeeded:
            Label("Done", systemImage: "checkmark").font(.system(size: 10, weight: .medium)).foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "exclamationmark.triangle.fill").font(.system(size: 10, weight: .medium)).foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if case .failed(let message) = status, !message.isEmpty {
            Text(message)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.red.opacity(0.9))
                .lineLimit(1)
                .help(message)
        } else {
            HStack(spacing: 4) {
                Text(item.command)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(1)
                Text("·")
                Text(item.workingDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            .foregroundStyle(.secondary)
            .help("\(item.command)\nin \(item.workingDirectory)")
        }
    }

    private func confirmDelete() {
        confirmingDelete = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            confirmingDelete = false
        }
    }
}

// MARK: - Small controls

private struct FormField: View {
    let placeholder: String
    @Binding var text: String
    var monospaced = false

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(monospaced ? .system(size: 12, design: .monospaced) : .system(size: 13))
            // Matches the native shortcut recorder's fixed .large height so the first row lines up.
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
            .foregroundStyle(.white)
    }
}

private struct IconChip: View {
    let symbol: String
    let isSelected: Bool
    let help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.75))
                .frame(width: 24, height: 24)
                .background(isSelected ? Color.white : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help ?? symbol)
        .accessibilityLabel(help ?? symbol)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct RowIconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}

struct PillButton: View {
    let title: String
    var systemImage: String?
    var primary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(primary ? .black : .white)
            .padding(.horizontal, 11)
            .frame(height: 26)
            .background(primary ? Color.white : Color.white.opacity(0.1), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
