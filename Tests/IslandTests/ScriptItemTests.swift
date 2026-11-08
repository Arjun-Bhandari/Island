import XCTest
@testable import Island

final class ScriptItemTests: XCTestCase {
    /// scripts.json written before icons existed must still load — Persistence
    /// falls back to an empty list on decode failure, which would wipe them.
    func testDecodesScriptsSavedBeforeIcons() throws {
        let legacy = #"[{"id":"9F1C2B9A-6B0E-4C55-9C7B-2D1E1B0C9A11","name":"API","command":"npm run dev","workingDirectory":"/tmp"}]"#
        let items = try JSONDecoder().decode([ScriptItem].self, from: Data(legacy.utf8))
        XCTAssertNil(items[0].icon)
        XCTAssertEqual(items[0].displayIcon, "server.rack")
    }

    func testSuggestedIcons() {
        XCTAssertEqual(ScriptIcon.suggested(for: "pnpm test"), "testtube.2")
        XCTAssertEqual(ScriptIcon.suggested(for: "git pull --rebase"), "arrow.triangle.branch")
        XCTAssertEqual(ScriptIcon.suggested(for: "docker compose up"), "square.stack.3d.up")
        XCTAssertEqual(ScriptIcon.suggested(for: "echo hi"), "terminal")
    }

    func testPickedIconWins() {
        XCTAssertEqual(ScriptItem(name: "x", command: "npm run dev", icon: "bolt").displayIcon, "bolt")
    }
}
