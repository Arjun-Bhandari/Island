import Foundation
import Observation

@Observable
final class TodoStore {
    private static let filename = "todos.json"

    var items: [TodoItem] = []

    init() {
        items = Persistence.load([TodoItem].self, from: Self.filename, default: [])
    }

    var remainingCount: Int {
        items.filter { !$0.isDone }.count
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed), at: 0)
        persist()
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isDone.toggle()
        persist()
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    /// Clears completed items older than today, keeping today's list fresh each morning.
    func clearCompleted() {
        items.removeAll { $0.isDone }
        persist()
    }

    private func persist() {
        Persistence.save(items, to: Self.filename)
    }
}
