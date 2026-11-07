import Foundation
import Observation
import Darwin
import KeyboardShortcuts

@Observable
final class ScriptStore {
    private static let filename = "scripts.json"

    var scripts: [ScriptItem] = []
    var statuses: [UUID: ScriptRunStatus] = [:]

    /// Processes currently running, so a dev-server-style command (one that
    /// never exits on its own) can be stopped from the UI instead of leaving
    /// it orphaned — which is exactly what caused the EADDRINUSE problem.
    private var runningProcesses: [UUID: Process] = [:]

    init() {
        scripts = Persistence.load([ScriptItem].self, from: Self.filename, default: [])
        registerRunShortcuts()
    }

    /// Per-script shortcut, recordable right on its row — no default, since
    /// there's no sane default for a user-defined, unbounded list. Registers
    /// harmlessly even if the user never assigns one.
    static func runShortcutName(for item: ScriptItem) -> KeyboardShortcuts.Name {
        .init("runScript_\(item.id.uuidString)")
    }

    private func registerRunShortcuts() {
        for item in scripts {
            KeyboardShortcuts.onKeyUp(for: Self.runShortcutName(for: item)) { [weak self] in
                self?.toggle(item)
            }
        }
    }

    /// Same run/stop toggle the row's button does, so one shortcut both
    /// starts a script and later stops it — no separate stop binding needed.
    func toggle(_ item: ScriptItem) {
        if isRunning(item) {
            stop(item)
        } else {
            run(item)
        }
    }

    func add(name: String, command: String, workingDirectory: String = NSHomeDirectory()) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedCommand.isEmpty else { return }
        let item = ScriptItem(name: trimmedName, command: trimmedCommand, workingDirectory: workingDirectory)
        scripts.append(item)
        KeyboardShortcuts.onKeyUp(for: Self.runShortcutName(for: item)) { [weak self] in
            self?.toggle(item)
        }
        persist()
    }

    func update(_ item: ScriptItem, name: String, command: String, workingDirectory: String) {
        guard let index = scripts.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedCommand.isEmpty else { return }
        scripts[index].name = trimmedName
        scripts[index].command = trimmedCommand
        scripts[index].workingDirectory = workingDirectory
        persist()
    }

    func delete(_ item: ScriptItem) {
        stop(item) // never leave a running process orphaned behind a deleted entry
        scripts.removeAll { $0.id == item.id }
        statuses[item.id] = nil
        KeyboardShortcuts.reset(Self.runShortcutName(for: item)) // free the keybinding
        persist()
    }

    func status(for item: ScriptItem) -> ScriptRunStatus {
        statuses[item.id] ?? .idle
    }

    func isRunning(_ item: ScriptItem) -> Bool {
        runningProcesses[item.id] != nil
    }

    /// Drives the running-script indicator on the collapsed pill, so a
    /// long-running script stays visible even with the notch closed.
    var hasRunningScript: Bool {
        !runningProcesses.isEmpty
    }

    /// Runs the command through the user's login shell so aliases/PATH from
    /// their profile resolve the same way they would in Terminal.
    func run(_ item: ScriptItem) {
        guard runningProcesses[item.id] == nil else { return }
        statuses[item.id] = .running

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", item.command]
        process.currentDirectoryURL = URL(fileURLWithPath: item.workingDirectory)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.terminationHandler = { [weak self] proc in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            DispatchQueue.main.async {
                guard let self else { return }
                self.runningProcesses[item.id] = nil
                if proc.terminationStatus == 0 {
                    self.statuses[item.id] = .succeeded
                } else {
                    self.statuses[item.id] = .failed(output.isEmpty ? "Exit code \(proc.terminationStatus)" : output)
                }
            }
        }

        do {
            try process.run()
            runningProcesses[item.id] = process
        } catch {
            statuses[item.id] = .failed(error.localizedDescription)
        }
    }

    /// Stops a running script. Sends SIGTERM first (lets dev servers clean
    /// up / free their port), then escalates to SIGKILL after a grace period
    /// if it hasn't exited.
    func stop(_ item: ScriptItem) {
        guard let process = runningProcesses[item.id] else { return }
        let pid = process.processIdentifier
        process.terminate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard self?.runningProcesses[item.id] != nil else { return }
            kill(pid, SIGKILL)
        }
    }

    private func persist() {
        Persistence.save(scripts, to: Self.filename)
    }
}
