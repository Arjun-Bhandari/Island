import Foundation
import Observation
import AppKit

private struct CleanupSnapshot: Codable {
    var rootDirectory: String
    var findings: [CleanupFinding]
}

@Observable
final class CleanupScanner {
    private static let filename = "cleanup_scan.json"

    var findings: [CleanupFinding] = []
    var selected: Set<UUID> = []
    var state: CleanupScanState = .idle
    var rootDirectory: String = NSHomeDirectory() + "/code"
    var lastError: String?

    /// Directory names that are safe to delete because every one of these
    /// tools regenerates them automatically on next build/install. Matching
    /// a name here stops the scan from descending further into it — we
    /// report the whole folder as one finding rather than its contents.
    private let junkDirectoryNames: Set<String> = [
        "node_modules", ".next", ".turbo", ".cache", "dist", "build",
        "target", ".build", "Pods", "venv", ".venv", "__pycache__",
        ".gradle", ".parcel-cache", ".pytest_cache"
    ]

    init() {
        // Last scan is remembered across launches — folder sizes can drift
        // between app restarts, but showing a stale-but-useful number beats
        // forcing a rescan every time just to see the reclaimable total.
        let snapshot = Persistence.load(CleanupSnapshot.self, from: Self.filename, default: CleanupSnapshot(rootDirectory: rootDirectory, findings: []))
        rootDirectory = snapshot.rootDirectory
        findings = snapshot.findings
        if !findings.isEmpty {
            state = .done
        }

        // Kick off a fresh scan in the background right away so Storage's
        // reclaimable number is current by the time anyone looks, without
        // blocking launch. The manual Scan button still works anytime.
        scan()
    }

    @MainActor func pickRootDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: rootDirectory)
        if let url = NotchController.runModal(panel) {
            rootDirectory = url.path
        }
    }

    func scan() {
        guard state != .scanning else { return }
        state = .scanning
        lastError = nil
        let root = rootDirectory
        let junkNames = junkDirectoryNames

        Task.detached { [weak self] in
            guard let self else { return }
            var results: [CleanupFinding] = []
            results.append(contentsOf: Self.scanTree(at: root, junkNames: junkNames))

            // DerivedData gets its own direct pass (it's one level of hashed
            // project folders, not nested junk names).
            let derivedDataPath = NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData"
            if FileManager.default.fileExists(atPath: derivedDataPath) {
                let size = Self.folderSize(at: derivedDataPath)
                if size > 0 {
                    results.append(CleanupFinding(path: URL(fileURLWithPath: derivedDataPath), kind: "Xcode DerivedData", sizeBytes: size))
                }
            }

            let sorted = results.sorted { $0.sizeBytes > $1.sizeBytes }
            await MainActor.run {
                self.findings = sorted
                self.state = .done
                self.persist()
            }
        }
    }

    /// Walks the tree, stopping and recording as soon as a directory name
    /// matches the safe-list — never looks inside a matched folder, so
    /// nothing but known regenerable caches is ever touched.
    private static func scanTree(at root: String, junkNames: Set<String>, depth: Int = 0, maxDepth: Int = 6) -> [CleanupFinding] {
        guard depth < maxDepth else { return [] }
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: root) else { return [] }

        var results: [CleanupFinding] = []
        for name in entries {
            let fullPath = root + "/" + name
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }

            if junkNames.contains(name) {
                let size = folderSize(at: fullPath)
                if size > 0 {
                    results.append(CleanupFinding(path: URL(fileURLWithPath: fullPath), kind: name, sizeBytes: size))
                }
            } else if !name.hasPrefix(".git") {
                results.append(contentsOf: scanTree(at: fullPath, junkNames: junkNames, depth: depth + 1, maxDepth: maxDepth))
            }
        }
        return results
    }

    private static func folderSize(at path: String) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        for item in enumerator {
            guard let name = item as? String else { continue }
            let full = path + "/" + name
            if let attrs = try? fm.attributesOfItem(atPath: full), let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        return total
    }

    var selectedTotalBytes: Int64 {
        findings.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    /// Everything the last scan found, selected or not — what System Monitor
    /// shows as "reclaimable" without requiring a trip to the Cleanup tab.
    var reclaimableTotalBytes: Int64 {
        findings.reduce(0) { $0 + $1.sizeBytes }
    }

    func toggle(_ finding: CleanupFinding) {
        if selected.contains(finding.id) {
            selected.remove(finding.id)
        } else {
            selected.insert(finding.id)
        }
    }

    func selectAll() {
        selected = Set(findings.map(\.id))
    }

    func deselectAll() {
        selected.removeAll()
    }

    /// Moves selected items to Trash — never a permanent delete — so a
    /// mistaken selection is always recoverable.
    func cleanSelected() {
        let toClean = findings.filter { selected.contains($0.id) }
        for finding in toClean {
            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: finding.path, resultingItemURL: &resultingURL)
            } catch {
                lastError = "Failed to trash \(finding.path.lastPathComponent): \(error.localizedDescription)"
            }
        }
        findings.removeAll { selected.contains($0.id) }
        selected.removeAll()
        persist()
    }

    private func persist() {
        Persistence.save(CleanupSnapshot(rootDirectory: rootDirectory, findings: findings), to: Self.filename)
    }
}
