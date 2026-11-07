import Foundation

struct CleanupFinding: Identifiable, Equatable, Codable {
    let id: UUID
    let path: URL
    let kind: String      // e.g. "node_modules", "DerivedData"
    let sizeBytes: Int64

    init(id: UUID = UUID(), path: URL, kind: String, sizeBytes: Int64) {
        self.id = id
        self.path = path
        self.kind = kind
        self.sizeBytes = sizeBytes
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

enum CleanupScanState: Equatable {
    case idle
    case scanning
    case done
}
