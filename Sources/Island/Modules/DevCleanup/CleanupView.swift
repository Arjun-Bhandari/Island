import SwiftUI

struct CleanupView: View {
    @Bindable var scanner: CleanupScanner
    @State private var confirmingClean = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            HStack {
                Text(scanner.rootDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Change…") { scanner.pickRootDirectory() }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }

            if let error = scanner.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            content
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
    }

    private var header: some View {
        HStack {
            Text("Cleanup")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button(scanner.state == .scanning ? "Scanning…" : "Scan") {
                scanner.scan()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.blue)
            .disabled(scanner.state == .scanning)
        }
    }

    @ViewBuilder
    private var content: some View {
        // Keep the previous results visible while a rescan runs instead of
        // blanking the list — it updates in place once the new scan lands.
        if scanner.state == .scanning, !scanner.findings.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                scanningBanner
                resultsList
            }
        } else {
            switch scanner.state {
            case .idle:
                Text("Scans for node_modules, build/dist caches, DerivedData, and similar — never source files. Moves to Trash, never deletes permanently.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .scanning:
                scanningBanner
            case .done:
                if scanner.findings.isEmpty {
                    Text("Nothing reclaimable found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    resultsList
                }
            }
        }
    }

    private var scanningBanner: some View {
        HStack {
            ProgressView().controlSize(.small)
            Text("Scanning \(scanner.rootDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~"))…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(scanner.selected.isEmpty ? "Select all" : "Deselect all") {
                    scanner.selected.isEmpty ? scanner.selectAll() : scanner.deselectAll()
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundStyle(.blue)
                Spacer()
                Text("\(ByteCountFormatter.string(fromByteCount: scanner.selectedTotalBytes, countStyle: .file)) selected")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(scanner.findings) { finding in
                        FindingRow(finding: finding, scanner: scanner)
                    }
                }
            }
            .frame(maxHeight: 160)

            if confirmingClean {
                confirmBar
            } else {
                Button("Move selected to Trash") {
                    confirmingClean = true
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(scanner.selected.isEmpty ? Color.secondary : Color.red)
                .disabled(scanner.selected.isEmpty)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var confirmBar: some View {
        HStack {
            Text("Trash \(scanner.selected.count) item(s)?")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Cancel") { confirmingClean = false }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("Confirm") {
                scanner.cleanSelected()
                confirmingClean = false
            }
            .buttonStyle(.plain)
            .font(.caption2)
            .foregroundStyle(.red)
        }
    }
}

private struct FindingRow: View {
    let finding: CleanupFinding
    let scanner: CleanupScanner

    private var isSelected: Bool { scanner.selected.contains(finding.id) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundStyle(isSelected ? .blue : .secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(finding.kind)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                Text(finding.path.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(finding.displaySize)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            scanner.toggle(finding)
        }
    }
}
