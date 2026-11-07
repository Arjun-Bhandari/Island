import SwiftUI
import AppKit
import KeyboardShortcuts

struct ScriptRunnerView: View {
    @Bindable var store: ScriptStore
    @State private var showingAdd = false
    @State private var editingItem: ScriptItem?
    @State private var newName = ""
    @State private var newCommand = ""
    @State private var newWorkingDirectory = NSHomeDirectory()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Scripts")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    if showingAdd {
                        cancelForm()
                    } else {
                        showingAdd = true
                    }
                } label: {
                    Image(systemName: showingAdd ? "xmark.circle.fill" : "plus.circle.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if showingAdd {
                addForm
            }

            if store.scripts.isEmpty {
                Text("No scripts yet — add a command, or import a .sh file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(store.scripts) { item in
                            ScriptRow(item: item, store: store, onEdit: { beginEdit(item) })
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
    }

    private var addForm: some View {
        VStack(spacing: 6) {
            TextField("Name", text: $newName)
                .textFieldStyle(.plain)
                .padding(8)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)

            TextField("Command, e.g. npm run build", text: $newCommand)
                .textFieldStyle(.plain)
                .padding(8)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .onSubmit(saveForm)

            HStack {
                Text("Runs in: \(displayPath(newWorkingDirectory))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Choose folder…") { pickWorkingDirectory() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }

            HStack {
                if editingItem == nil {
                    Button("Import script file…") { importScriptFile() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Button(editingItem == nil ? "Add script" : "Save changes", action: saveForm)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    private func beginEdit(_ item: ScriptItem) {
        editingItem = item
        newName = item.name
        newCommand = item.command
        newWorkingDirectory = item.workingDirectory
        showingAdd = true
    }

    private func saveForm() {
        if let editingItem {
            store.update(editingItem, name: newName, command: newCommand, workingDirectory: newWorkingDirectory)
        } else {
            store.add(name: newName, command: newCommand, workingDirectory: newWorkingDirectory)
        }
        cancelForm()
    }

    private func cancelForm() {
        editingItem = nil
        newName = ""
        newCommand = ""
        newWorkingDirectory = NSHomeDirectory()
        showingAdd = false
    }

    private func pickWorkingDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: newWorkingDirectory)
        if panel.runModal() == .OK, let url = panel.url {
            newWorkingDirectory = url.path
        }
    }

    /// Lets the user pick an existing .sh/.command file and turns it into a
    /// runnable script entry — no need to retype the command by hand.
    private func importScriptFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        if panel.runModal() == .OK, let url = panel.url {
            if newName.isEmpty {
                newName = url.deletingPathExtension().lastPathComponent
            }
            newCommand = "bash \(shellQuote(url.path))"
            newWorkingDirectory = url.deletingLastPathComponent().path
            showingAdd = true
        }
    }

    private func shellQuote(_ path: String) -> String {
        "'\(path.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func displayPath(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}

private struct ScriptRow: View {
    let item: ScriptItem
    let store: ScriptStore
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if store.isRunning(item) {
                    store.stop(item)
                } else {
                    store.run(item)
                }
            } label: {
                statusIcon
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                Text(item.command)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("in \(item.workingDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~"))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary.opacity(0.7))
                if case .failed(let message) = store.status(for: item), !message.isEmpty {
                    Text(message)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                if store.isRunning(item) {
                    Text("Running — tap to stop")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            KeyboardShortcuts.Recorder(for: ScriptStore.runShortcutName(for: item))
                .controlSize(.small)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                store.delete(item)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch store.status(for: item) {
        case .idle:
            Image(systemName: "play.circle")
                .foregroundStyle(.secondary)
        case .running:
            Image(systemName: "stop.circle.fill")
                .foregroundStyle(.orange)
        case .succeeded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}
