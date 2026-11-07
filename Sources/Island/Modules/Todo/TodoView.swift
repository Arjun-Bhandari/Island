import SwiftUI

struct TodoView: View {
    @Bindable var store: TodoStore
    @State private var newTitle: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            TextField("Add a todo for today…", text: $newTitle)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .padding(8)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .onSubmit(addTodo)

            if store.items.isEmpty {
                Text("Nothing yet — add your first task.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(store.items) { item in
                            TodoRow(item: item, store: store)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
        .onAppear { fieldFocused = true }
    }

    private var header: some View {
        HStack {
            Text("Today")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Text("\(store.remainingCount) left")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func addTodo() {
        store.add(newTitle)
        newTitle = ""
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let store: TodoStore

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.toggle(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(size: 13))
                .foregroundStyle(item.isDone ? Color.secondary : Color.white)
                .strikethrough(item.isDone)
                .lineLimit(1)

            Spacer()

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
}
