import Foundation

/// Single place for file-based storage. Each module gets its own JSON file
/// under ~/Library/Application Support/Island/.
enum Persistence {
    static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Island", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for filename: String) -> URL {
        appSupportDirectory.appendingPathComponent(filename)
    }

    static func load<T: Decodable>(_ type: T.Type, from filename: String, default defaultValue: T) -> T {
        let url = url(for: filename)
        guard let data = try? Data(contentsOf: url) else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    static func save<T: Encodable>(_ value: T, to filename: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url(for: filename), options: .atomic)
    }
}
