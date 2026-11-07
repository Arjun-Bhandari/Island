import SwiftUI

struct MonitorView: View {
    let stats: SystemStats
    let cleanupScanner: CleanupScanner

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("System")
                .font(.headline)
                .foregroundStyle(.white)

            StatRow(
                icon: "cpu",
                label: "CPU",
                valueText: String(format: "%.0f%%", stats.cpuUsage),
                fraction: stats.cpuUsage / 100
            )

            StatRow(
                icon: "memorychip",
                label: "Memory (RAM)",
                valueText: String(format: "%.1f / %.0f GB", stats.memoryUsedGB, stats.memoryTotalGB),
                fraction: stats.memoryTotalGB > 0 ? stats.memoryUsedGB / stats.memoryTotalGB : 0
            )

            StatRow(
                icon: "internaldrive",
                label: "Storage",
                valueText: String(format: "%.0f / %.0f GB", stats.diskUsedGB, stats.diskTotalGB),
                fraction: stats.diskTotalGB > 0 ? stats.diskUsedGB / stats.diskTotalGB : 0
            )

            reclaimableRow
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
    }

    private var reclaimableRow: some View {
        HStack {
            Label("Reclaimable", systemImage: "trash")
                .font(.system(size: 13))
                .foregroundStyle(.white)
            Spacer()
            Text(cleanupScanner.findings.isEmpty
                 ? "— (scan to check)"
                 : ByteCountFormatter.string(fromByteCount: cleanupScanner.reclaimableTotalBytes, countStyle: .file))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(cleanupScanner.findings.isEmpty ? Color.secondary : Color.orange)
        }
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let valueText: String
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(max(fraction, 0), 1))
                }
            }
            .frame(height: 5)
        }
    }

    private var barColor: Color {
        fraction > 0.85 ? .red : (fraction > 0.6 ? .orange : .green)
    }
}
