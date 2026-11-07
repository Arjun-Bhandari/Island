import SwiftUI

/// Default landing tab: a wide, landscape dashboard rather than a single
/// module, so hovering gives you the day's status without picking a tab.
struct HomeView: View {
    let todoStore: TodoStore
    let cleanupScanner: CleanupScanner
    let systemStats: SystemStats

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                dateHeader
                todaySummary
            }
            .frame(width: 220, alignment: .leading)

            Divider().background(.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 14) {
                CalendarGridView()
                quickStats
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide))
                .font(.headline)
                .foregroundStyle(.white)
            Text(Date.now, format: .dateTime.month(.wide).day())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var pendingItems: [TodoItem] {
        todoStore.items.filter { !$0.isDone }
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(todoStore.items.count - pendingItems.count)/\(todoStore.items.count) done")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            if pendingItems.isEmpty {
                Text(todoStore.items.isEmpty ? "No todos yet." : "All caught up 🎉")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(pendingItems.prefix(4)) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.secondary)
                                .frame(width: 4, height: 4)
                            Text(item.title)
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }
                    if pendingItems.count > 4 {
                        Text("+ \(pendingItems.count - 4) more")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var quickStats: some View {
        HStack(spacing: 8) {
            QuickStatTile(icon: "cpu", value: String(format: "%.0f%%", systemStats.cpuUsage), label: "CPU")
            QuickStatTile(
                icon: "memorychip",
                value: String(format: "%.1f GB", systemStats.memoryUsedGB),
                label: "Memory"
            )
            QuickStatTile(
                icon: "trash",
                value: cleanupScanner.findings.isEmpty ? "—" : ByteCountFormatter.string(fromByteCount: cleanupScanner.reclaimableTotalBytes, countStyle: .file),
                label: "Reclaimable"
            )
        }
    }
}

private struct QuickStatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}
